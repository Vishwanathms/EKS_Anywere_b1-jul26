Yes. For an enterprise training, I recommend **not using the default single-node EKS Anywhere cluster**. Instead, use a **2-node production-style deployment** so students understand the real architecture.

---

# Lab 2.2 – Deploying a Production EKS Anywhere Cluster on VMware vSphere

**Module 2 – Building Production EKS Anywhere**

**Duration:** 90 Minutes

---

# Business Scenario

Your organization wants to build an on-premises Kubernetes platform using **Amazon EKS Anywhere** on VMware vSphere.

The platform team has already installed:

* Ubuntu Administration VM
* Docker
* kubectl
* eksctl-anywhere
* govc

Your task is to provision a production Kubernetes cluster consisting of:

* **1 Control Plane VM**
* **1 Worker Node VM**

using Cluster API.

---

# Lab Architecture

```text
                    vCenter Server
                           │
        -------------------------------------
        │                                   │
Bootstrap Cluster (Kind)             Datastore
        │
        │
        ▼
Creates Production Cluster
        │
        ├───────────────┐
        │               │
        ▼               ▼
Control Plane VM     Worker VM
192.168.10.101      192.168.10.102

        │
        └──── Kubernetes Cluster ──────┐
                                       │
                                CoreDNS
                                CNI
                                kube-proxy
                                Metrics Server
```

---

# Target Cluster

| Component          | Value              |
| ------------------ | ------------------ |
| Cluster Name       | production-cluster |
| Kubernetes Version | 1.34               |
| Control Plane      | 1 VM               |
| Worker Nodes       | 1 VM               |
| Provider           | VMware vSphere     |
| OS                 | Ubuntu 24 OVA      |
| Network            | VM Network         |
| CNI                | Cilium             |

---

# VM Configuration

## Control Plane

| Property | Value         |
| -------- | ------------- |
| CPU      | 4             |
| RAM      | 8 GB          |
| Disk     | 40 GB         |
| IP       | DHCP / Static |

---

## Worker Node

| Property | Value |
| -------- | ----- |
| CPU      | 4     |
| RAM      | 8 GB  |
| Disk     | 40 GB |

---

# Prerequisites

Verify

```bash
docker version
kubectl version --client
kind version
govc version
eksctl anywhere version
```

---

Verify Docker

```bash
sudo systemctl status docker
```

Expected

```
Active (running)
```

---

# Step 1 Create Working Directory

```bash
mkdir -p ~/eka/module2
cd ~/eka/module2
```

---

# Step 2 Export vCenter Variables

Example

```bash
export GOVC_URL='vcsa.lab.local'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='Password123!'
export GOVC_INSECURE=1
```

Verify

```bash
govc about
```

---

# Step 3 Generate Cluster Configuration

```bash
eksctl anywhere generate clusterconfig production-cluster \
--provider vsphere > cluster.yaml
```

Verify

```bash
ls
```

```
cluster.yaml
```

---

# Step 4 Edit Cluster Configuration

Open

```bash
nano cluster.yaml
```

---

## Cluster Section

```yaml
apiVersion: anywhere.eks.amazonaws.com/v1alpha1
kind: Cluster
metadata:
  name: production-cluster

spec:

  kubernetesVersion: "1.34"

  controlPlaneConfiguration:

    count: 1

    endpoint:
      host: 192.168.10.100

    machineGroupRef:
      kind: VSphereMachineConfig
      name: cp-machine

  workerNodeGroupConfigurations:

  - name: md-0

    count: 1

    machineGroupRef:
      kind: VSphereMachineConfig
      name: worker-machine

  datacenterRef:
    kind: VSphereDatacenterConfig
    name: datacenter
```

---

## Datacenter Configuration

```yaml
apiVersion: anywhere.eks.amazonaws.com/v1alpha1
kind: VSphereDatacenterConfig

metadata:
  name: datacenter

spec:

  server: vcsa.lab.local

  datacenter: Datacenter

  datastore: datastore1

  network: VM Network

  folder: EKSAnywhere

  resourcePool: Cluster/Resources

  insecure: true
```

---

## Control Plane Machine

```yaml
apiVersion: anywhere.eks.amazonaws.com/v1alpha1
kind: VSphereMachineConfig

metadata:
  name: cp-machine

spec:

  numCPUs: 4

  memoryMiB: 8192

  diskGiB: 40

  datastore: datastore1

  folder: EKSAnywhere

  osFamily: ubuntu

  template: ubuntu-24-template

  users:

  - name: administrator
```

---

## Worker Machine

```yaml
apiVersion: anywhere.eks.amazonaws.com/v1alpha1
kind: VSphereMachineConfig

metadata:
  name: worker-machine

spec:

  numCPUs: 4

  memoryMiB: 8192

  diskGiB: 40

  datastore: datastore1

  folder: EKSAnywhere

  osFamily: ubuntu

  template: ubuntu-24-template

  users:

  - name: administrator
```

---

# Step 5 Validate Configuration

```bash
eksctl anywhere exp validate create cluster \
-f cluster.yaml
```

Expected

```
Validation successful
```

---

# Step 6 Deploy Cluster

Run

```bash
eksctl anywhere create cluster \
-f cluster.yaml
```

Deployment takes approximately

```
15–20 minutes
```

---

During deployment students will observe

```
Bootstrap Cluster Created

↓

Cluster API Installed

↓

CAPV Installed

↓

Cert Manager Installed

↓

Control Plane VM Created

↓

Worker VM Created

↓

Kubernetes Installed

↓

Bootstrap Cluster Deleted

↓

Management transferred
```

---

# Step 7 Observe vCenter

Open vCenter

Navigate

```
Datacenter

↓

VMs

↓

EKSAnywhere Folder
```

Students should see

```
production-cluster-control-plane

production-cluster-md-0
```

Observe

```
Creating

↓

Powering On

↓

Booting Ubuntu

↓

Cloud Init

↓

Joining Kubernetes
```

---

# Step 8 Verify Cluster

After completion

```bash
kubectl get nodes
```

Expected

```
NAME                                 STATUS

production-cluster-control-plane     Ready

production-cluster-md-0              Ready
```

---

# Step 9 Verify Namespaces

```bash
kubectl get ns
```

Expected

```
default

kube-system

eksa-system

cilium-system
```

---

# Step 10 Verify System Pods

```bash
kubectl get pods -A
```

Students should observe

```
CoreDNS

Cilium

kube-proxy

metrics-server

etcd

kube-apiserver

controller-manager

scheduler
```

---

# Step 11 Verify Control Plane

```bash
kubectl get pods -n kube-system -o wide
```

Expected

```
kube-apiserver

etcd

scheduler

controller-manager
```

Running on

```
production-cluster-control-plane
```

---

# Step 12 Verify Worker Node

```bash
kubectl describe node production-cluster-md-0
```

Observe

```
CPU

Memory

Labels

Capacity

Allocatable
```

---

# Step 13 Verify Kubernetes Version

```bash
kubectl version
```

---

Verify Nodes

```bash
kubectl get nodes -o wide
```

Expected

```
NAME                     ROLES           VERSION

control-plane            control-plane   v1.34.x

worker                   <none>          v1.34.x
```

---

# Step 14 Verify Cluster Info

```bash
kubectl cluster-info
```

Expected

```
Kubernetes Control Plane

CoreDNS
```

---

# Step 15 Verify Cilium

```bash
kubectl get pods -n kube-system
```

or

```bash
kubectl get pods -A | grep cilium
```

Expected

```
cilium

cilium-operator
```

---

# Step 16 Deploy Test Application

Create deployment

```bash
kubectl create deployment nginx \
--image=nginx
```

Scale

```bash
kubectl scale deployment nginx \
--replicas=2
```

---

Verify

```bash
kubectl get pods -o wide
```

Students will observe

```
One pod on Control Plane

One pod on Worker
```

This confirms scheduling across nodes.

---

# Step 17 Verify Cluster API Objects

```bash
kubectl get clusters
```

Expected

```
production-cluster
```

---

Machines

```bash
kubectl get machines
```

Expected

```
control-plane

worker
```

---

Machine Deployments

```bash
kubectl get machinedeployments
```

Expected

```
md-0
```

---

# Step 18 Verify VM from govc

```bash
govc vm.info production-cluster-control-plane
```

Worker

```bash
govc vm.info production-cluster-md-0
```

---

# Final Architecture

```text
                   Kubernetes Cluster

              +-------------------------+

              Control Plane VM
              kube-apiserver
              etcd
              scheduler
              controller-manager

                       │

              ---------------------

                       │

                Worker Node

                kubelet

                kube-proxy

                Cilium

                User Pods
```

---

# Expected Outcome

Students should have:

* ✅ Bootstrap cluster created automatically
* ✅ One control plane VM provisioned in vCenter
* ✅ One worker VM provisioned in vCenter
* ✅ Kubernetes cluster fully operational
* ✅ Both nodes in `Ready` state
* ✅ Core system pods healthy
* ✅ Test workload scheduled across the cluster
* ✅ Verified Cluster API resources and corresponding VMware VMs

### Instructor Note

For a **production-focused EKS Anywhere course**, I recommend extending this into **three progressive labs** rather than one large exercise:

1. **Lab 2.2:** Deploy a 1 Control Plane + 1 Worker cluster (cluster creation fundamentals).
2. **Lab 2.3:** Scale the cluster by adding additional worker nodes using `MachineDeployment` (cluster expansion).
3. **Lab 2.4:** Convert the cluster to a highly available deployment with **3 Control Plane + 3 Worker nodes**, including upgrades and failure simulation. This progression closely mirrors how EKS Anywhere is introduced and managed in enterprise environments.
