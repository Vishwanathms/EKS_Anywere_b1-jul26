Yes. For your **EKS Anywhere → Rafay Self-Hosted** training, I recommend using **OpenEBS LocalPV Hostpath**. It is lightweight, easy to install, and ideal for lab environments. Note, however, that **LocalPV is not highly available**—if a node fails, volumes on that node become unavailable. This is acceptable for training but not for production. ([OpenEBS][1])

For your environment:

* VMware vSphere
* 3-node EKS Anywhere Cluster
* Rafay Self-Hosted Controller
* Training/Lab Environment

OpenEBS LocalPV is an appropriate choice.

---

# Instructor Lab Manual

## Lab 01 – Installing OpenEBS LocalPV on EKS Anywhere

### Duration

45–60 Minutes

---

# Lab Objective

After completing this lab, you will be able to:

* Understand Kubernetes StorageClasses
* Install OpenEBS
* Configure LocalPV
* Create a Default StorageClass
* Dynamically provision Persistent Volumes
* Validate PVC creation
* Prepare the cluster for Rafay installation

---

# Lab Topology

```text
                   VMware vCenter

        +----------------------------------+
        |      EKS Anywhere Cluster        |
        |                                  |
        |  Control Plane                   |
        |                                  |
        |  Worker-1                        |
        |                                  |
        |  Worker-2                        |
        +----------------------------------+

                    │
                    ▼

             OpenEBS LocalPV

                    │
                    ▼

         Dynamic Persistent Volumes
```

---

# Prerequisites

Verify cluster access.

```bash
kubectl cluster-info
```

Expected Output

```text
Kubernetes control plane is running
CoreDNS is running
```

---

Verify Nodes

```bash
kubectl get nodes
```

Example

```text
NAME            STATUS   ROLES
cp-01           Ready    control-plane
worker-01       Ready
worker-02       Ready
```

---

Verify Current StorageClasses

```bash
kubectl get storageclass
```

Current Result

```text
No resources found
```

This confirms the cluster has no storage provisioner configured.

---

# Task 1 – Verify Node Storage

On every node

```bash
df -h
```

Example

```text
Filesystem      Size
/dev/sda2       150G
```

OpenEBS HostPath uses local disk storage from the node filesystem.

---

Create a dedicated directory on **every node** (control plane and workers):

```bash
sudo mkdir -p /var/openebs/local
```

Set permissions:

```bash
sudo chmod 777 /var/openebs/local
```

Verify:

```bash
ls -ld /var/openebs/local
```

---

# Task 2 – Install OpenEBS

Create the namespace:

```bash
kubectl create namespace openebs
```

Verify:

```bash
kubectl get ns openebs
```

---

Add the Helm repository:

```bash
helm repo add openebs https://openebs.github.io/openebs
```

Update the repository:

```bash
helm repo update
```

Verify:

```bash
helm search repo openebs
```

The OpenEBS Helm chart is published through the official Helm repository. ([OpenEBS][1])

---

# Task 3 – Install OpenEBS

Install the chart:

```bash
helm install openebs \
openebs/openebs \
-n openebs \
--create-namespace
```

Wait a few minutes for the deployment to complete.

---

Verify the Helm release:

```bash
helm list -n openebs
```

Expected:

```text
NAME       STATUS
openebs    deployed
```

---

# Task 4 – Verify OpenEBS Pods

```bash
kubectl get pods -n openebs
```

Typical output:

```text
NAME                                 READY
openebs-localpv-provisioner          1/1
openebs-ndm                          1/1
openebs-ndm-node-exporter            1/1
```

Wait until every pod is in the **Running** state.

---

Describe a pod

```bash
kubectl describe pod <pod-name> -n openebs
```

Review

* Events
* Container Image
* Mounts
* Readiness

---

# Task 5 – Verify CRDs

```bash
kubectl get crd | grep openebs
```

You should see several OpenEBS Custom Resource Definitions.

---

# Task 6 – Check Existing StorageClasses

```bash
kubectl get storageclass
```

Sometimes the installation creates StorageClasses automatically.

If none are marked as default, continue with the next task.

---

# Task 7 – Create Default StorageClass

Create `openebs-local.yaml`

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-hostpath
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"

provisioner: openebs.io/local

volumeBindingMode: WaitForFirstConsumer

reclaimPolicy: Delete
```

Apply it:

```bash
kubectl apply -f openebs-local.yaml
```

Verify:

```bash
kubectl get storageclass
```

Expected:

```text
NAME                         PROVISIONER              DEFAULT

openebs-hostpath (default)   openebs.io/local         Yes
```

---

# Task 8 – Create Test PVC

Create `pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim

metadata:
  name: demo-pvc

spec:
  accessModes:
    - ReadWriteOnce

  resources:
    requests:
      storage: 2Gi
```

Apply

```bash
kubectl apply -f pvc.yaml
```

Verify

```bash
kubectl get pvc
```

Expected

```text
NAME       STATUS

demo-pvc   Bound
```

---

# Task 9 – Verify Persistent Volume

```bash
kubectl get pv
```

Example

```text
NAME

pvc-xxxxxxxx
```

Describe it

```bash
kubectl describe pv <pv-name>
```

Review:

* Capacity
* StorageClass
* Node Affinity
* Reclaim Policy

---

# Task 10 – Test with a Pod

Create `nginx-pvc.yaml`

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx-storage

spec:

  containers:

  - image: nginx

    name: nginx

    volumeMounts:

    - mountPath: /usr/share/nginx/html

      name: storage

  volumes:

  - name: storage

    persistentVolumeClaim:

      claimName: demo-pvc
```

Deploy

```bash
kubectl apply -f nginx-pvc.yaml
```

Verify

```bash
kubectl get pods
```

Wait for

```text
Running
```

---

# Task 11 – Verify Volume Mount

```bash
kubectl exec -it nginx-storage -- bash
```

Inside the container:

```bash
df -h
```

Create a test file:

```bash
echo "OpenEBS Working" > /usr/share/nginx/html/index.html
```

Exit:

```bash
exit
```

---

# Task 12 – Verify Persistence

Delete the Pod:

```bash
kubectl delete pod nginx-storage
```

Recreate it:

```bash
kubectl apply -f nginx-pvc.yaml
```

Verify the data is still present:

```bash
kubectl exec -it nginx-storage -- cat /usr/share/nginx/html/index.html
```

Expected:

```text
OpenEBS Working
```

---

# Task 13 – Cleanup

```bash
kubectl delete pod nginx-storage

kubectl delete pvc demo-pvc
```

Verify:

```bash
kubectl get pvc

kubectl get pv
```

---

# Validation Checklist

| Task                         | Status |
| ---------------------------- | ------ |
| OpenEBS installed            | ✅      |
| Pods Running                 | ✅      |
| Default StorageClass created | ✅      |
| PVC Bound                    | ✅      |
| PV Created                   | ✅      |
| Pod Running                  | ✅      |
| Volume Mounted               | ✅      |
| Data Persistent              | ✅      |

---

## Notes for the Next Lab

Once this lab is complete, your EKS Anywhere cluster will have dynamic persistent storage available. This is a prerequisite for deploying stateful components required by the Rafay Self-Hosted Controller, such as PostgreSQL and OpenSearch. ([OpenEBS][1])

**One recommendation before proceeding:** newer OpenEBS releases use CSI-based storage engines, and some older `openebs.io/local` examples found online are deprecated. For your training manual, I'll base all manifests and commands on the current OpenEBS 4.x implementation so that every step works with the latest release rather than older tutorials.

[1]: https://openebs.io/docs/?utm_source=chatgpt.com "OpenEBS Documentation | OpenEBS Docs"
