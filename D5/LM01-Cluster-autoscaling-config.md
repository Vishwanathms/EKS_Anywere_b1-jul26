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
    maxCount: 4
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