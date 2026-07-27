---

# Complete Lab – Installing Cluster Autoscaler on EKS Anywhere

## Prerequisites

Before starting, verify:

* ✅ EKS Anywhere cluster is running
* ✅ Management cluster is healthy
* ✅ Worker node group exists
* ✅ Package Controller is installed
* ✅ MachineDeployment is available
* ✅ vCenter credentials are configured
* ✅ OVA Template exists in the Content Library

---

# Step 1 – Verify Cluster

```bash
kubectl get nodes
```

Expected

```
cp-01
cp-02

worker-01
worker-02
```

---

# Step 2 – Verify MachineDeployment

```bash
kubectl get machinedeployments -A
```

Expected

```
NAMESPACE     NAME
production    md-0
```

---

# Step 3 – Verify Packages Controller

```bash
kubectl get pods -A | grep package
```

Expected

```
package-controller-manager
Running
```

If it isn't installed:

```bash
eksctl anywhere install packagecontroller \
    --cluster production-cluster
```

---

# Step 4 – Configure Worker Autoscaling

Open the cluster specification.

```bash
kubectl get clusters.anywhere.eks.amazonaws.com production-cluster-lXX -o yaml > cluster-XX.yaml
```
* change the "XX" to your student number before running it

Locate:

```yaml
workerNodeGroupConfigurations:
- name: md-0
  count: 2
```

Modify to:

```yaml
workerNodeGroupConfigurations:
- name: md-0

  count: 2

  autoscalingConfiguration:

    minCount: 2

    maxCount: 5
```

Save.

---

# Step 5 – Apply Configuration

```bash
eksctl anywhere upgrade cluster \
    -f cluster.yaml
```

Wait until the upgrade completes.

---

# Step 6 – Verify Autoscaling Configuration

```bash
kubectl get machinedeployment -A
```

Describe it

```bash
kubectl describe machinedeployment md-0
```

Students should verify:

```
Min Replicas

2

Max Replicas

5
```

---

# Step 7 – Generate Package Manifest

```bash
eksctl anywhere generate package cluster-autoscaler \
      --cluster production-cluster \
      > cluster-autoscaler.yaml
```

---

# Step 8 – Open Manifest

```bash
vi cluster-autoscaler.yaml
```

Locate

```yaml
config:
```

Modify

```yaml
config: |-

  cloudProvider: clusterapi

  autoDiscovery:

    clusterName: production-cluster-lXX

  scaleDown:

    enabled: true
```
* change the "XX" to your student number before running it

---

# Step 9 – Install Package

```bash
eksctl anywhere create packages \
     -f cluster-autoscaler.yaml
```

---

# Step 10 – Verify Installation

```bash
kubectl get pods -A | grep autoscaler
```

Expected

```
cluster-autoscaler

Running
```

---

# Step 11 – View Logs

```bash
kubectl logs deployment/cluster-autoscaler \
      -n eksa-system -f
```

Students should observe:

```
Watching MachineDeployments

Watching Pending Pods
```

---

# Step 12 – Verify Worker Nodes

```bash
kubectl get nodes
```

Expected

```
2 Worker Nodes
```

---

# Step 13 – Deploy Test Application

Create a deployment that requests significant CPU and memory.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-app
spec:
  replicas: 15
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
```

Apply:

```bash
kubectl apply -f stress-app.yaml
```

---

# Step 14 – Observe Pending Pods

```bash
kubectl get pods
```

Some pods should remain:

```
Pending
```
* In-case non of the pods are in pending , increase the number of pods under relicas in the above deployment file and apply again


Describe one:

```bash
kubectl describe pod <pod-name>
```

Expected scheduling message:

```
0/2 nodes available

Insufficient CPU
```

---

# Step 15 – Watch Autoscaler

Terminal 1:

```bash
kubectl logs deployment/cluster-autoscaler \
    -n eksa-system -f
```

Terminal 2:

```bash
kubectl get machines -A -w
```

Terminal 3:

```bash
kubectl get nodes -w
```

---

# Step 16 – Verify vCenter

Open **vCenter** and observe:

* A new worker VM is cloned from the Content Library template.
* The VM powers on and obtains an IP address.
* The machine begins the Kubernetes join process.

---

# Step 17 – Verify New Worker

```bash
kubectl get nodes
```

Expected:

```
worker-01
worker-02
worker-03
```

---

# Step 18 – Verify Pod Scheduling

```bash
kubectl get pods -o wide
```

Previously pending pods should now transition to `Running` and be distributed onto the new worker node.

---

# Step 19 – Scale Down the Workload

```bash
kubectl scale deployment stress-app --replicas=2
```

---

# Step 20 – Observe Scale Down

Watch:

```bash
kubectl get machines -A -w
```

```bash
kubectl get nodes -w
```

```bash
kubectl logs deployment/cluster-autoscaler \
     -n eksa-system -f
```

Eventually, the autoscaler should identify an underutilized worker node, drain it, remove the corresponding `Machine`, and vSphere will delete the VM.

---

# Final Validation

Students should verify:

* ✔ Cluster Autoscaler package is installed and running.
* ✔ Worker node group has `autoscalingConfiguration` with the expected minimum and maximum node counts.
* ✔ Resource requests on pods trigger pending scheduling when capacity is exhausted.
* ✔ Cluster Autoscaler detects pending pods and increases the `MachineDeployment` replica count.
* ✔ Cluster API creates a new `Machine`.
* ✔ vSphere provisions a new worker VM from the Content Library.
* ✔ The new node joins the cluster and reaches the `Ready` state.
* ✔ Pending pods are scheduled automatically.
* ✔ Scaling the workload down leads to automatic node removal after the autoscaler's scale-down interval.

This provides students with the complete lifecycle of autoscaling in EKS Anywhere, from configuration through scale-up, workload recovery, and scale-down.
