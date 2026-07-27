# Lab: Autoscaling a Cluster API Worker Pool (EKS Anywhere / vSphere)

**Cluster:** `production-cluster-a31` · **Worker group:** `production-cluster-a31-md-0` (min 2 / max 4) · **Kubernetes:** 1.35

## What you're building

A self-managed EKS Anywhere cluster only grows its worker nodes when something
tells it to. In this lab that "something" is the open-source **Cluster
Autoscaler**, running with the `clusterapi` cloud provider, watching your
`MachineDeployment` and scaling it between the bounds already set in
`cluster.yaml`. You'll deploy a workload that doesn't fit on the current
nodes, watch pods sit `Pending`, install the autoscaler, and watch the node
count — and the pods — resolve on their own.

> **Why not the AWS curated `cluster-autoscaler` package?** EKS Anywhere ships
> one, but it pulls images from AWS's own ECR account, gated behind an
> **EKS Anywhere Enterprise Subscription**. On the open-source distribution
> that pull is always rejected (`403 Forbidden`), regardless of IAM
> permissions. The manifest in this lab pulls from the public
> `registry.k8s.io` registry instead — no AWS entitlement needed.

Every command below assumes:
```bash
export KUBECONFIG=/home/labuser/eka-labs/Cluster-3/production-cluster-a31-eks-a-cluster.kubeconfig
```

---

## Phase 0 — Confirm your lab facts

The autoscaler manifest has to name your cluster and node group exactly. Don't
assume — read them off the live cluster.

```bash
kubectl get machinedeployments -A
```
Record two things from the output: the **NAME** column and the **NAMESPACE**
column. On this cluster they are `production-cluster-a31-md-0` and
`eksa-system`. If yours differ, substitute your own values everywhere below.

```bash
grep -A3 autoscalingConfiguration /home/labuser/eka-labs/Cluster-3/cluster.yaml
```
Confirm `minCount` / `maxCount` — this lab uses `2` / `4`.

---

## Phase 1 — Create a workload that outgrows the cluster

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: stress
  template:
    metadata:
      labels:
        app: stress
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: "1000m"
            memory: "1Gi"
EOF
```
Five pods requesting a full vCPU each, on a two-worker-node group where each
node has 2 vCPU — deliberately more than fits.

**✅ Checkpoint — some pods should be stuck:**
```bash
kubectl get pods -l app=stress
```
```
NAME                          READY   STATUS    NODE
stress-app-xxxxxxxxxx-xxxxx   0/1     Pending   <none>
stress-app-xxxxxxxxxx-xxxxx   0/1     Pending   <none>
stress-app-xxxxxxxxxx-xxxxx   0/1     Pending   <none>
stress-app-xxxxxxxxxx-xxxxx   1/1     Running   production-cluster-a31-md-0-...
stress-app-xxxxxxxxxx-xxxxx   1/1     Running   production-cluster-a31-md-0-...
```
If all 5 are `Running` already, your nodes are bigger than this lab assumes —
raise `replicas` or the per-pod `cpu` request until at least one is `Pending`,
then continue.

---

## Phase 2 — Write the autoscaler manifest

Create `/home/labuser/eka-labs/Cluster-3/cluster-autoscaler.yaml` with the
content below. Every RBAC rule here was earned the hard way in a prior run of
this lab — skip that pain by starting from the complete version:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: eksa-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-autoscaler
rules:
  - apiGroups: [""]
    resources: ["events", "endpoints"]
    verbs: ["create", "patch"]
  - apiGroups: [""]
    resources: ["pods/eviction"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/status"]
    verbs: ["update"]
  - apiGroups: [""]
    resources: ["endpoints"]
    resourceNames: ["cluster-autoscaler"]
    verbs: ["get", "update"]
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["watch", "list", "get", "update"]
  - apiGroups: [""]
    resources: ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["batch", "extensions"]
    resources: ["jobs"]
    verbs: ["get", "list", "patch", "watch"]
  - apiGroups: ["extensions"]
    resources: ["replicasets", "daemonsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["watch", "list"]
  - apiGroups: ["apps"]
    resources: ["daemonsets", "replicasets", "statefulsets"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities", "volumeattachments"]
    verbs: ["watch", "list", "get"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["list", "watch", "get", "create", "update"]
  - apiGroups: ["resource.k8s.io"]
    resources: ["resourceslices", "resourceclaims", "deviceclasses"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["infrastructure.cluster.x-k8s.io"]
    resources: ["vspheremachinetemplates", "vspheremachines", "vsphereclusters"]
    verbs: ["watch", "list", "get"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["create"]
  - apiGroups: ["coordination.k8s.io"]
    resourceNames: ["cluster-autoscaler"]
    resources: ["leases"]
    verbs: ["get", "update"]
  - apiGroups: ["cluster.x-k8s.io"]
    resources: ["machinedeployments", "machinedeployments/scale", "machinepools", "machinepools/scale", "machines", "machinesets", "machinesets/scale"]
    verbs: ["get", "list", "update", "patch", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
  - kind: ServiceAccount
    name: cluster-autoscaler
    namespace: eksa-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: eksa-system
  labels:
    app: cluster-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
        - name: cluster-autoscaler
          image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.35.2
          command:
            - ./cluster-autoscaler
            - --v=4
            - --stderrthreshold=info
            - --cloud-provider=clusterapi
            - --node-group-auto-discovery=clusterapi:namespace=eksa-system,clusterName=production-cluster-a31
            - --scale-down-delay-after-add=5m
            - --scale-down-unneeded-time=5m
          resources:
            requests:
              cpu: 100m
              memory: 300Mi
```

Two values only make sense for *this* cluster — change them if Phase 0 gave
you different answers:
- `namespace=eksa-system,clusterName=production-cluster-a31` in the
  `--node-group-auto-discovery` flag
- The image tag `v1.35.2` should match your cluster's Kubernetes minor
  version (`kubectl version` → server minor version). Check available tags
  with `curl -sL https://registry.k8s.io/v2/autoscaling/cluster-autoscaler/tags/list`.

---

## Phase 3 — Apply it

```bash
kubectl apply -f /home/labuser/eka-labs/Cluster-3/cluster-autoscaler.yaml
```

**✅ Checkpoint — pod comes up clean:**
```bash
kubectl get pods -n eksa-system -l app=cluster-autoscaler
```
```
NAME                                  READY   STATUS    RESTARTS   AGE
cluster-autoscaler-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

---

## Phase 4 — Confirm the control loop is actually healthy

A `Running` pod only means the container started — it does not mean the
autoscaler's control loop is making progress. Read its own self-reported
status:

```bash
kubectl get cm cluster-autoscaler-status -n kube-system -o jsonpath='{.data.status}'
```

**✅ Checkpoint — expect this shape** (give it up to a minute after the pod
starts):
```yaml
autoscalerStatus: Running
nodeGroups:
- health:
    cloudProviderTarget: 2
    maxSize: 4
    minSize: 2
    status: Healthy
  name: MachineDeployment/eksa-system/production-cluster-a31-md-0
  scaleUp:
    status: NoActivity   # or "InProgress" if it's already reacting to Phase 1's pending pods
```
If `autoscalerStatus` stays `Initializing` and never moves to `Running`, or
`scaleUp.status` is `Backoff`, go straight to **Troubleshooting** below —
don't wait it out, it won't self-resolve.

---

## Phase 5 — Watch it scale

```bash
watch kubectl get nodes
```
Within a few minutes of Phase 3 (scan interval is 10s, node provisioning
takes longer), you should see the node count grow from 2 workers toward 4.

**✅ Checkpoint:**
```bash
kubectl get machinedeployment production-cluster-a31-md-0 -n eksa-system
```
```
NAME                          DESIRED   CURRENT   READY   AVAILABLE   PHASE
production-cluster-a31-md-0   4         4         4       4           Running
```

---

## Phase 6 — Confirm the workload recovered

```bash
kubectl get pods -l app=stress
```
More replicas should now be `Running` than in Phase 1. With `maxCount: 4` and
2 vCPU per node, 4 of the 5 `stress-app` replicas fit — the 5th stays
`Pending` on purpose. That's `maxCount` doing its job, not a failure. Raising
`maxCount` in `cluster.yaml` (and re-applying the cluster spec) is the only
way to let it schedule.

---

## Phase 7 — Clean up

```bash
kubectl delete -f /home/labuser/eka-labs/Cluster-3/cluster-autoscaler.yaml
kubectl delete deployment stress-app
```
Leaving `stress-app` running is harmless but will keep the node group pinned
near `maxCount`; delete it once you're done observing scale-down behavior
(the autoscaler waits `--scale-down-unneeded-time=5m` of idle capacity before
removing a node).

---

## Troubleshooting

Read `kubectl logs -n eksa-system deploy/cluster-autoscaler --tail=200 | grep -i forbidden`
and the status configmap's `backoffInfo.errorMessage` first — both name the
exact missing permission, no guessing required. Known failure signatures:

| Symptom | Cause | Fix |
|---|---|---|
| `autoscalerStatus: Initializing` forever, logs show `forbidden` on `resourceslices`/`resourceclaims`/`deviceclasses` | Scheduler-framework informers can't sync without RBAC on Dynamic Resource Allocation objects | Confirm the `resource.k8s.io` rule is present in the `ClusterRole` |
| Same freeze, logs show `forbidden` on `vspheremachinetemplates` | ClusterAPI's vSphere infrastructure provider objects aren't readable | Confirm the `infrastructure.cluster.x-k8s.io` rule is present |
| `cluster-autoscaler-status` configmap never appears in `kube-system` | Missing `create`/`update` on `configmaps` | Confirm the `configmaps` rule includes those verbs (cosmetic issue, but hides your only health signal) |
| Status shows `scaleUp.status: Backoff` with `cannot patch resource "machinedeployments/scale"` | `ClusterRole` granted `update` but not `patch` on the scale subresource | Confirm `patch` is in the `cluster.x-k8s.io` rule's verb list |
| `ErrImagePull` / `403 Forbidden` pulling from `*.dkr.ecr.*.amazonaws.com` | You're on the AWS curated package path, not this lab's manifest | Not applicable here — this lab's image comes from `registry.k8s.io`, which needs no AWS credentials |

If you hit an error not listed here: the pattern is always the same —
`forbidden` in the logs names a resource, add a `get/list/watch` (and
`patch`/`update`/`create` if it's a write) rule for that resource to the
`ClusterRole`, and re-apply. RBAC changes take effect immediately; no pod
restart needed.
