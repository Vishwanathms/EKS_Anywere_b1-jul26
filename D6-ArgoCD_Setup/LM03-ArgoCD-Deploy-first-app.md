# Lab 3 – Deploy the First GitOps Application

## Objective

Deploy an application using only Git.

---

# Duration

45 Minutes

---

# Learning Objectives

Students will

* Create an ArgoCD Application
* Deploy resources
* Verify application health
* Understand Desired State

---

## Step 1 – Create Application

Applications

↓

NEW APP

---

Application Name

```
nginx-demo
```

Project

```
default
```

---

Repository

```
gitops-lab
```

---

Revision

```
main
```

---

Path

```
/
```

---

Destination Cluster

```
https://kubernetes.default.svc
```

---

Namespace

```
gitops-demo
```

---

## Step 2 – Create

Click

```
Create
```

---

## Step 3 – Sync

Click

```
SYNC

Synchronize
```

---

## Step 4 – Observe Deployment

ArgoCD

```
Healthy

Synced
```

---

## Step 5 – Verify

```
kubectl get all -n gitops-demo
```

Expected

```
Deployment

ReplicaSet

Pods

Service
```

---

## Step 6 – Observe Resource Tree

Students should identify

Deployment

↓

ReplicaSet

↓

Pods

---

## Step 7 – Verify UI

Open workload

```
kubectl get svc
```

or expose via LoadBalancer if required.

---

# Lab Challenge

Increase replicas to

```
5
```

Commit changes.

Observe deployment.

---

# Expected Outcome

Application successfully deployed from Git.

---

---

