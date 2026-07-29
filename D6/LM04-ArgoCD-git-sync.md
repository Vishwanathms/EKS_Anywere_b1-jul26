# Lab 4 – Git Synchronization and Self-Healing

## Objective

Understand Continuous GitOps synchronization.

---

# Duration

45 Minutes

---

# Learning Objectives

Students will

* Modify Git
* Observe Sync Status
* Perform Manual Sync
* Enable Auto Sync
* Test Self-Healing

---

## Step 1 – Edit Deployment

Change

```
replicas: 2
```

to

```
replicas: 4
```

Commit

```
git add .

git commit -m "Scale Application"

git push
```

---

## Step 2 – Observe ArgoCD

Status

```
OutOfSync
```

---

## Step 3 – Manual Sync

Click

```
SYNC
```

Observe

```
Progressing

Healthy
```

---

## Step 4 – Verify

```
kubectl get pods -n gitops-demo
```

Expected

```
4 Pods
```

---

## Step 5 – Enable Auto Sync

Application

↓

SYNC POLICY

↓

Enable

```
Automatic Sync

Self Heal

Prune
```

---

## Step 6 – Test Self-Healing

Delete a pod manually.

```
kubectl delete pod <pod-name> -n gitops-demo
```

Observe

ArgoCD recreates the missing pod automatically to match the desired state.

---

## Step 7 – Test Drift Detection

Manually scale the deployment outside Git.

```
kubectl scale deployment nginx \
--replicas=1 \
-n gitops-demo
```

Within a short period, ArgoCD detects the drift and restores the replica count defined in Git (4 replicas).

---

## Step 8 – Test Prune

Delete the `service.yaml` file from the Git repository.

```
git rm service.yaml
git commit -m "Remove service"
git push
```

With **Prune** enabled, ArgoCD automatically deletes the Service resource from the EKS Anywhere cluster during the next synchronization.

---

# Final Verification

Run the following commands to confirm the application state:

```bash
kubectl get all -n gitops-demo
kubectl get applications -n argocd
```

The application should report:

* **Sync Status:** Synced
* **Health Status:** Healthy
* **Source of Truth:** Git Repository

---

# End-of-Module Outcome

By completing these four labs, students will be able to:

* Install and configure ArgoCD on an EKS Anywhere cluster.
* Connect Git repositories securely to ArgoCD.
* Deploy Kubernetes applications using the GitOps workflow.
* Perform manual and automatic synchronization.
* Enable self-healing and prune operations.
* Understand how ArgoCD continuously reconciles the desired state stored in Git with the actual state running on an EKS Anywhere cluster.
