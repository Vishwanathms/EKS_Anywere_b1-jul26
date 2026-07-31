For an **EKS Anywhere Production Administrator**, students should learn not just `kubectl get nodes`, but also how to inspect the entire cluster state. Below is a comprehensive list of **read-only inspection commands** that are highly relevant for EKS Anywhere. These commands are safe to run and are commonly used for cluster validation and troubleshooting.

---

# Lab 1 – Explore EKS Anywhere Cluster

## Objective

Verify the health of an EKS Anywhere cluster and inspect its Kubernetes resources before deploying workloads.

---

# Task 1 – Verify Cluster Connectivity

Check that `kubectl` can communicate with the cluster.

```bash
kubectl cluster-info
```

Expected Output

```text
Kubernetes control plane is running at https://<api-server>:6443
CoreDNS is running at ...
```

---

Display client and server versions.

```bash
kubectl version
```

or

```bash
kubectl version --short
```

---

Check current Kubernetes context.

```bash
kubectl config current-context
```

---

Display all configured contexts.

```bash
kubectl config get-contexts
```

---

Display cluster configuration.

```bash
kubectl config view
```

---

# Task 2 – Display Cluster Nodes

List all nodes.

```bash
kubectl get nodes
```

---

Display additional information.

```bash
kubectl get nodes -o wide
```

Example

```text
NAME        STATUS   ROLES           AGE   VERSION
cp-01       Ready    control-plane   15d   v1.31.x
cp-02       Ready    control-plane   15d   v1.31.x
worker-01   Ready    <none>          15d
worker-02   Ready    <none>          15d
worker-03   Ready    <none>          15d
worker-04   Ready    <none>          15d
```

---

Show node labels.

```bash
kubectl get nodes --show-labels
```

---

Display node names only.

```bash
kubectl get nodes -o name
```

---

Display node IP addresses.

```bash
kubectl get nodes -o wide
```

Observe

* Internal IP
* OS
* Kernel Version
* Container Runtime

---

# Task 3 – Inspect a Node

View complete node information.

```bash
kubectl describe node worker-01
```

Observe

* Capacity
* Allocatable
* Labels
* Taints
* Conditions
* Running Pods
* Events
* Resource Allocation

---

Display node information in YAML.

```bash
kubectl get node worker-01 -o yaml
```

---

Display node information in JSON.

```bash
kubectl get node worker-01 -o json
```

---

# Task 4 – Verify System Pods

Display all system namespace pods.

```bash
kubectl get pods -n kube-system
```

---

Display more details.

```bash
kubectl get pods -n kube-system -o wide
```

---

Display every pod in every namespace.

```bash
kubectl get pods -A
```

or

```bash
kubectl get pods --all-namespaces
```

---

Display pod IP addresses.

```bash
kubectl get pods -A -o wide
```

---

# Task 5 – Verify Cluster Components

Display namespaces.

```bash
kubectl get ns
```

---

Display deployments.

```bash
kubectl get deployments -A
```

---

Display daemonsets.

```bash
kubectl get daemonsets -A
```

---

Display statefulsets.

```bash
kubectl get statefulsets -A
```

---

Display replica sets.

```bash
kubectl get rs -A
```

---

Display services.

```bash
kubectl get svc -A
```

---

Display endpoints.

```bash
kubectl get endpoints -A
```

---

Display endpoint slices.

```bash
kubectl get endpointslices -A
```

---

# Task 6 – Verify Control Plane Health

View control plane pods.

```bash
kubectl get pods -n kube-system
```

Verify components such as:

* kube-apiserver
* kube-controller-manager
* kube-scheduler
* etcd
* CoreDNS
* kube-proxy
* CNI (Cilium or other configured CNI)
* metrics-server (if installed)

---

Describe a control plane pod.

```bash
kubectl describe pod <pod-name> -n kube-system
```

---

View pod logs.

```bash
kubectl logs <pod-name> -n kube-system
```

---

# Task 7 – Inspect Cluster Events

Display recent events.

```bash
kubectl get events -A
```

---

Sort events chronologically.

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

---

View only Warning events.

```bash
kubectl get events -A --field-selector type=Warning
```

---

# Task 8 – Resource Usage (Metrics Server Required)

Display CPU and memory usage of nodes.

```bash
kubectl top nodes
```

---

Display CPU and memory usage of pods.

```bash
kubectl top pods -A
```

---

# Task 9 – View Kubernetes API Resources

Display all supported resource types.

```bash
kubectl api-resources
```

---

Display API versions.

```bash
kubectl api-versions
```

---

Explain a Kubernetes object.

```bash
kubectl explain pod
```

---

Explain a specific field.

```bash
kubectl explain deployment.spec.template.spec
```

---

# Task 10 – Explore EKS Anywhere Custom Resources

EKS Anywhere installs several Custom Resource Definitions (CRDs). Display them:

```bash
kubectl get crds
```

Filter EKS Anywhere CRDs:

```bash
kubectl get crds | grep anywhere
```

or

```bash
kubectl get crds | grep eks
```

---

Display EKS Anywhere custom resources.

```bash
kubectl get clusters.anywhere.eks.amazonaws.com -A
```

```bash
kubectl get vspheredatacenterconfigs.anywhere.eks.amazonaws.com -A
```

```bash
kubectl get vspheremachineconfigs.anywhere.eks.amazonaws.com -A
```

```bash
kubectl get bundles.anywhere.eks.amazonaws.com
```

---

Describe the EKS Anywhere cluster resource.

```bash
kubectl describe clusters.anywhere.eks.amazonaws.com <cluster-name>
```

---

# Task 11 – View Cluster Certificates

View Kubernetes certificate signing requests.

```bash
kubectl get csr
```

---

# Task 12 – Verify Storage

Display StorageClasses.

```bash
kubectl get storageclass
```

---

Display Persistent Volumes.

```bash
kubectl get pv
```

---

Display Persistent Volume Claims.

```bash
kubectl get pvc -A
```

---

# Task 13 – Verify Networking

Display services.

```bash
kubectl get svc -A
```

---

Display ingress resources.

```bash
kubectl get ingress -A
```

---

Display network policies.

```bash
kubectl get networkpolicy -A
```

---

# Task 14 – Cluster Summary

Display all resources in the current namespace.

```bash
kubectl get all
```

---

Display all resources across every namespace.

```bash
kubectl get all -A
```

---

## Common Read-Only Commands for EKS Anywhere Administrators

| Command                                              | Purpose                                      |
| ---------------------------------------------------- | -------------------------------------------- |
| `kubectl cluster-info`                               | Verify API server connectivity               |
| `kubectl get nodes -o wide`                          | View node inventory                          |
| `kubectl describe node <node>`                       | Inspect node health and capacity             |
| `kubectl get pods -A -o wide`                        | List all pods with node placement            |
| `kubectl get svc -A`                                 | View services                                |
| `kubectl get deployments -A`                         | View deployments                             |
| `kubectl get daemonsets -A`                          | View DaemonSets                              |
| `kubectl get statefulsets -A`                        | View StatefulSets                            |
| `kubectl get events -A --sort-by=.lastTimestamp`     | Troubleshoot recent events                   |
| `kubectl top nodes`                                  | Monitor node CPU and memory usage            |
| `kubectl top pods -A`                                | Monitor pod resource usage                   |
| `kubectl get crds`                                   | List installed Custom Resource Definitions   |
| `kubectl get clusters.anywhere.eks.amazonaws.com -A` | View EKS Anywhere cluster resources          |
| `kubectl api-resources`                              | List all available Kubernetes resource types |
| `kubectl explain <resource>`                         | Display API documentation for a resource     |

These commands form a solid foundation for EKS Anywhere operations and are frequently used in production for health checks, validation, and troubleshooting.
