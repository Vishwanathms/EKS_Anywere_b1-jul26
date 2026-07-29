Below is a production-oriented lab manual designed specifically for your **EKS Anywhere (vSphere) Training**. It assumes:

* EKS Anywhere workload cluster is already running.
* ArgoCD will be installed inside the EKS Anywhere cluster.
* GitHub will be used as the Git repository.
* Students already have kubectl access to their cluster.
* Each student has their own namespace and Git repository.

---

# Lab 1 – Install ArgoCD on an EKS Anywhere Cluster

## Lab Objective

In this lab you will:

* Understand why GitOps is required
* Install ArgoCD
* Expose ArgoCD UI
* Login to ArgoCD
* Verify all components

---

# Lab Duration

**45 Minutes**

---

# Architecture

```
Student Laptop
      │
      │ kubectl
      ▼
+-----------------------------------+
|      EKS Anywhere Cluster         |
|                                   |
| Namespace: argocd                 |
|                                   |
|  +----------------------------+   |
|  | ArgoCD Server              |   |
|  +----------------------------+   |
|                                   |
|  +----------------------------+   |
|  | Repo Server                |   |
|  +----------------------------+   |
|                                   |
|  +----------------------------+   |
|  | Application Controller     |   |
|  +----------------------------+   |
|                                   |
|  +----------------------------+   |
|  | Redis                      |   |
|  +----------------------------+   |
+-----------------------------------+
```

---

# Learning Objectives

By the end of this lab students will be able to

* Install ArgoCD
* Understand ArgoCD components
* Access Web UI
* Retrieve Admin Password
* Login successfully

---

# Step 1 – Verify Cluster

```
kubectl cluster-info
```

Expected

```
Kubernetes control plane is running...
```

---

## Step 2 – Verify Worker Nodes

```
kubectl get nodes
```

Example

```
NAME             STATUS
cp01             Ready
worker01         Ready
worker02         Ready
```

---

## Step 3 – Create Namespace

```
kubectl create namespace argocd
```

Verify

```
kubectl get ns
```

---

## Step 4 – Install ArgoCD

```
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Expected

```
namespace unchanged

deployment.apps created

service created

configmap created

secret created
```

Installation usually takes **2–5 minutes**.

---

## Step 5 – Watch Installation

```
kubectl get pods -n argocd -w
```

Wait until every pod shows

```
Running
```

Example

```
argocd-server

argocd-repo-server

argocd-application-controller

argocd-dex-server

argocd-redis
```

---

## Step 6 – Verify Deployments

```
kubectl get deploy -n argocd
```

Expected

```
NAME

argocd-server

argocd-repo-server

argocd-applicationset-controller

argocd-notifications-controller
```

---

## Step 7 – Expose ArgoCD

For the lab use LoadBalancer (MetalLB already configured).

```
kubectl patch svc argocd-server \
-n argocd \
-p '{"spec":{"type":"LoadBalancer"}}'
```

---

## Step 8 – Get External IP

```
kubectl get svc -n argocd
```

Example

```
NAME             TYPE           EXTERNAL-IP

argocd-server    LoadBalancer   192.168.10.180
```

Open

```
https://192.168.10.180
```

---

## Step 9 – Retrieve Admin Password

```
kubectl get secret argocd-initial-admin-secret \
-n argocd \
-o jsonpath="{.data.password}" | base64 -d
```

Example

```
P@ssw0rd123
```

---

## Step 10 – Login

Username

```
admin
```

Password

```
(previous command output)
```

---

## Step 11 – Explore UI

Students should identify

* Applications
* Projects
* Repositories
* Settings
* Clusters
* Application History
* Sync Status

---

# Verification

```
kubectl get all -n argocd
```

Every component should be

```
Running
```

---

# Lab Challenge

* Restart ArgoCD Server
* Observe self-healing
* Login again

---

# Expected Outcome

Students successfully install and access ArgoCD running on EKS Anywhere.

---

