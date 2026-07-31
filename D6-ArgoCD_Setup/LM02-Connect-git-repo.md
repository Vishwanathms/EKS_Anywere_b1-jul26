---

# Lab 2 – Connect a Git Repository to ArgoCD

## Lab Objective

Connect a GitHub repository to ArgoCD so it can monitor Kubernetes manifests.

---

# Duration

30 Minutes

---

# Learning Objectives

Students will

* Create a Git repository
* Add Kubernetes manifests
* Connect GitHub with ArgoCD
* Verify repository connectivity

---

# Repository Structure

```
gitops-lab/

├── deployment.yaml

├── service.yaml

└── namespace.yaml
```

---

## Step 1 – Create Repository

Example

```
gitops-lab
```

Initialize locally

```
mkdir gitops-lab

cd gitops-lab

git init
```

---

## Step 2 – Create Namespace Manifest

namespace.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gitops-demo
```

---

## Step 3 – Create Deployment

deployment.yaml

Deploy nginx

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: gitops-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

---

## Step 4 – Create Service

service.yaml

Create cluster service for nginx

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: gitops-demo
spec:
  selector:
    app: nginx
  ports:
  - port: 80
```

---

## Step 5 – Push to GitHub

```
git add .

git commit -m "Initial GitOps"

git branch -M main

git remote add origin https://github.com/<user>/gitops-lab.git

git push origin main
```

---

## Step 6 – Add Repository in ArgoCD

Navigate

```
Settings

Repositories

Connect Repo
```

Provide

Repository URL

Username (if private)

PAT Token (if private)

---

## Step 7 – Verify Repository

Repository should show

```
Successful
```

Green icon

---

# Verification

Repositories page shows

```
Connected
```

---

# Lab Challenge

Connect another repository containing Helm charts.

---

# Expected Outcome

ArgoCD successfully communicates with GitHub.

---

---

