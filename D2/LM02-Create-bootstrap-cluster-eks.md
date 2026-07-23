# Lab Manual 2.1 – Deploying the Bootstrap Cluster (EKS Anywhere)

**Course:** Enterprise Kubernetes with EKS Anywhere
**Module:** Module 2 – Building Production EKS Anywhere
**Lab Duration:** 45–60 Minutes
**Difficulty:** Intermediate

---

# Lab Objective

In this lab you will deploy the **Bootstrap Cluster**, which is the first cluster created by EKS Anywhere.

Students will learn:

* Why a Bootstrap Cluster is required
* How Cluster API uses the Bootstrap Cluster
* Bootstrap cluster lifecycle
* How to deploy it
* Verify all Cluster API components
* Understand what happens behind the scenes

---

# Learning Outcomes

After completing this lab, students will be able to:

✓ Create a Bootstrap Cluster

✓ Understand Cluster API workflow

✓ Verify Cluster API controllers

✓ Monitor bootstrap activities

✓ Troubleshoot deployment issues

---

# Architecture

```
                    Student Laptop
                          │
             eksctl-anywhere CLI
                          │
                cluster create
                          │
             ─────────────────────────
             Bootstrap Cluster
             (KinD Kubernetes Cluster)
             ─────────────────────────
                  │
                  │ Runs
                  │
        • Cluster API
        • CAPV Controller
        • Bootstrap Provider
        • Control Plane Provider
                  │
                  ▼
      Creates Production Cluster
```

---

# Lab Environment

Ubuntu 24 VM

| Component       | Version   |
| --------------- | --------- |
| Ubuntu          | 24.04     |
| Docker          | Installed |
| kubectl         | Installed |
| eksctl-anywhere | Installed |
| kind            | Installed |
| govc            | Installed |
| Helm            | Installed |

---

# Estimated Time

| Task                     | Time   |
| ------------------------ | ------ |
| Verify Environment       | 10 min |
| Create Cluster Folder    | 5 min  |
| Create Cluster Config    | 10 min |
| Deploy Bootstrap Cluster | 15 min |
| Verify Components        | 15 min |

---

# Step 1 – Verify Required Software

Verify Docker

```bash
docker version
```

Expected

```
Client:
 Version: 28.x

Server:
 Version: 28.x
```

---

Verify kubectl

```bash
kubectl version --client
```

Expected

```
Client Version: v1.34.x
```

---

Verify kind

```bash
kind version
```

Expected

```
kind v0.30.x
```

---

Verify eksctl-anywhere

```bash
eksctl anywhere version
```

Expected

```
v0.xx.x
```

---

Verify govc

```bash
govc version
```

Expected

```
govc 0.xx.x
```

---

# Step 2 – Verify Docker Service

```bash
sudo systemctl status docker
```

Expected

```
Active: active (running)
```

If not running

```bash
sudo systemctl start docker
```

---

# Step 3 – Verify Access to vCenter

Export environment variables.

Example:

```bash
export GOVC_URL='vcenter.lab.local'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='Password123!'
export GOVC_INSECURE=1
```

Verify connectivity

```bash
govc about
```

Expected

```
Name: VMware vCenter Server
Vendor: VMware
Version: 8.x
```

---

# Step 4 – Create Working Directory

```bash
mkdir -p ~/eka-labs/module2
```

Move into directory

```bash
cd ~/eka-labs/module2
```

Verify

```bash
pwd
```

Expected

```
/home/student/eka-labs/module2
```

---

# Step 5 – Generate Cluster Configuration

Generate a sample cluster configuration.

```bash
eksctl anywhere generate clusterconfig production-cluster \
--provider vsphere > cluster.yaml
```

Verify file

```bash
ls
```

Expected

```
cluster.yaml
```

---

# Step 6 – Review Cluster Configuration

Open the configuration.

```bash
nano cluster.yaml
```

Students should locate sections such as:

```
Cluster

VSphereDatacenterConfig

VSphereMachineConfig
```

Do **not** modify the file in this lab. The instructor provides a prepared configuration.

---

# Step 7 – Validate Cluster Configuration

Run validation.

```bash
eksctl anywhere exp validate create cluster \
-f cluster.yaml
```

Expected

```
Validating configuration...

Success
```

---

# Step 8 – Start Cluster Creation

Run

```bash
eksctl anywhere create cluster \
-f cluster.yaml
```

This command performs several activities automatically.

Students should observe console output.

Example

```
Creating bootstrap cluster...

Installing Cluster API...

Installing CAPV...

Installing etcdadm Bootstrap Provider...

Installing kubeadm Control Plane...

Installing Cert Manager...

Waiting for controllers...

Bootstrap cluster ready.
```

---

# What Happens Behind the Scenes?

During deployment the CLI performs the following operations.

```
Step 1
↓

Creates KinD Cluster

↓

Installs Cert Manager

↓

Installs Cluster API

↓

Installs CAPV

↓

Installs Bootstrap Provider

↓

Installs Control Plane Provider

↓

Installs Machine Controller

↓

Bootstrap Cluster Ready
```

---

# Step 9 – Verify Bootstrap Cluster Exists

List Kubernetes contexts.

```bash
kubectl config get-contexts
```

Expected

```
bootstrap-cluster
```

Switch context.

```bash
kubectl config use-context bootstrap-cluster
```

---

# Step 10 – Verify Nodes

```bash
kubectl get nodes
```

Expected

```
NAME
bootstrap-cluster-control-plane
```

Status

```
Ready
```

---

# Step 11 – Verify Namespaces

```bash
kubectl get ns
```

Expected namespaces

```
default

kube-system

capi-system

capv-system

cert-manager

eksa-system
```

---

# Step 12 – Verify Pods

```bash
kubectl get pods -A
```

Expected

```
cert-manager

cluster-api-controller

capv-controller-manager

kubeadm-bootstrap-controller

kubeadm-control-plane-controller
```

All pods should be

```
Running
```

---

# Step 13 – Verify Cluster API Objects

```bash
kubectl get deployments -A
```

Expected deployments include

```
cluster-api-controller-manager

capv-controller-manager

cert-manager

coredns
```

---

# Step 14 – Inspect Cluster API Controllers

```bash
kubectl get pods -n capi-system
```

Expected

```
cluster-api-controller-manager
```

---

Check CAPV

```bash
kubectl get pods -n capv-system
```

Expected

```
capv-controller-manager
```

---

Check Cert Manager

```bash
kubectl get pods -n cert-manager
```

Expected

```
cert-manager

cainjector

webhook
```

---

# Step 15 – Verify Docker Bootstrap Cluster

Since Bootstrap Cluster runs on KinD.

List Docker containers.

```bash
docker ps
```

Expected

```
bootstrap-cluster-control-plane
```

Students can understand that

**Bootstrap Cluster is actually running inside Docker.**

---

# Step 16 – Observe Bootstrap Logs

Open another terminal.

```bash
docker logs bootstrap-cluster-control-plane
```

Observe Kubernetes startup logs.

---

# Step 17 – Monitor Cluster Creation

Watch pods continuously.

```bash
watch kubectl get pods -A
```

Observe

Pods transitioning

```
Pending

↓

ContainerCreating

↓

Running
```

---

# Step 18 – Verify Bootstrap Cluster Health

```bash
kubectl cluster-info
```

Expected

```
Kubernetes control plane is running
```

---

# Understanding the Bootstrap Cluster Lifecycle

```
User

↓

Create Cluster

↓

Bootstrap Cluster Created

↓

Cluster API Installed

↓

Production Cluster Created

↓

Workload Cluster Ready

↓

Bootstrap Cluster Deleted
```

The Bootstrap Cluster exists **only during cluster creation** and is automatically removed after the Production Cluster becomes operational.

---

# Verification Checklist

| Check                     | Status |
| ------------------------- | ------ |
| Docker Running            | ☐      |
| govc Connected            | ☐      |
| Bootstrap Cluster Created | ☐      |
| Kubernetes Node Ready     | ☐      |
| Cluster API Installed     | ☐      |
| CAPV Installed            | ☐      |
| Cert Manager Running      | ☐      |
| kube-system Healthy       | ☐      |

---

# Troubleshooting

## Issue 1 – Docker Not Running

Verify:

```bash
sudo systemctl status docker
```

Start Docker:

```bash
sudo systemctl start docker
```

---

## Issue 2 – Bootstrap Cluster Not Created

Check KinD clusters:

```bash
kind get clusters
```

If a previous bootstrap cluster exists, delete it:

```bash
kind delete cluster --name bootstrap-cluster
```

---

## Issue 3 – Controller Pods Stuck

Inspect pod status:

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

Review logs:

```bash
kubectl logs <pod-name> -n <namespace>
```

---

## Issue 4 – vCenter Connectivity Fails

Verify environment variables:

```bash
env | grep GOVC
```

Test connection:

```bash
govc about
```

---

# Lab Summary

In this lab you successfully:

* Verified the EKS Anywhere prerequisites.
* Connected to the vCenter environment.
* Generated and validated an EKS Anywhere cluster configuration.
* Created the Bootstrap Cluster (KinD-based).
* Observed the installation of Cluster API, CAPV, kubeadm providers, and cert-manager.
* Verified bootstrap health using Kubernetes, Docker, and Cluster API resources.
* Learned how the Bootstrap Cluster orchestrates creation of the production workload cluster before being automatically removed.

> **Instructor Note:** In the next lab, **Deploy Production Cluster**, students will reuse the Bootstrap Cluster created here to provision the permanent EKS Anywhere workload cluster on vSphere, observe node provisioning, and verify the control plane transition.
