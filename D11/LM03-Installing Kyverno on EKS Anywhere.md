# Module 11 – Supply Chain Security

# Lab 3 – Installing Kyverno on EKS Anywhere

## Lab Duration

**90 Minutes**

## Difficulty

**Intermediate**

## Environment

* Ubuntu 24.04
* EKS Anywhere Cluster
* kubectl Installed
* Helm Installed
* Cluster-admin access

---

# Lab Objective

In this lab, students will install **Kyverno**, a Kubernetes-native policy engine, into the existing **EKS Anywhere cluster**.

After completing this lab, students will be able to:

* Understand the role of an Admission Controller
* Install Kyverno using Helm
* Verify all Kyverno components
* Understand Mutating Webhooks
* Understand Validating Webhooks
* Explore the Kyverno Policy Engine
* Verify Webhook configurations
* View Kyverno logs
* Understand the request flow inside Kubernetes

---

# Lab Architecture

```text
                     kubectl apply
                           │
                           ▼
                   Kubernetes API Server
                           │
        ┌──────────────────┴─────────────────┐
        │                                    │
        ▼                                    ▼
 Validating Webhook                  Mutating Webhook
        │                                    │
        └──────────────┬─────────────────────┘
                       ▼
                Kyverno Policy Engine
                       │
         Validate • Mutate • Generate • Verify
                       │
                       ▼
                  Resource Stored
                     in etcd
```

---

# What is Kyverno?

Kyverno is a **Kubernetes Native Policy Engine**.

Unlike Open Policy Agent (OPA), Kyverno policies are written using native Kubernetes YAML.

Kyverno allows administrators to:

* Validate resources
* Mutate resources
* Generate resources
* Verify image signatures
* Enforce security best practices
* Prevent insecure deployments

---

# Why Do We Need Kyverno?

Without Kyverno

```
Developer
      │
kubectl apply
      │
      ▼
API Server
      │
      ▼
Pod Created
```

Any YAML that is syntactically valid can be created.

Problems

* Containers run as root
* No resource limits
* Privileged Pods
* Latest image tags
* Missing labels
* No security context

---

With Kyverno

```
Developer
      │
kubectl apply
      │
      ▼
API Server
      │
      ▼
Kyverno
      │
Validate Policy
      │
Pass / Reject
      ▼
Pod Created
```

Every request is checked before Kubernetes stores it.

---

# Prerequisites

Verify Kubernetes Cluster

```bash
kubectl cluster-info
```

Expected

```
Kubernetes control plane is running
```

---

Verify Nodes

```bash
kubectl get nodes
```

Expected

```
NAME          STATUS
cp01          Ready
worker01      Ready
```

---

Verify Helm

```bash
helm version
```

Example

```
version.BuildInfo
```

---

If Helm is missing

Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify

```bash
helm version
```

---

# Step 1 – Add Kyverno Helm Repository

Add repository

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
```

Expected

```
"kyverno" has been added
```

---

Update repository

```bash
helm repo update
```

Expected

```
Successfully got an update
```

---

# Step 2 – Search Available Charts

```bash
helm search repo kyverno
```

Expected

```
NAME

kyverno/kyverno

kyverno/policy-reporter

kyverno/kyverno-policies
```

Discuss the charts:

| Chart            | Purpose                     |
| ---------------- | --------------------------- |
| kyverno          | Installs Kyverno Controller |
| kyverno-policies | Sample security policies    |
| policy-reporter  | Reporting dashboard         |

Only install **kyverno** in this lab.

---

# Step 3 – Create Namespace

Check if namespace exists

```bash
kubectl get ns
```

If absent

```bash
kubectl create namespace kyverno
```

Verify

```bash
kubectl get ns kyverno
```

Expected

```
kyverno
```

---

# Step 4 – Install Kyverno

Install the latest stable chart

```bash
helm install kyverno kyverno/kyverno \
  --namespace kyverno
```

Expected output

```
NAME: kyverno

STATUS: deployed

REVISION: 1
```

Installation may take 1–2 minutes.

---

# Step 5 – Verify Helm Release

```bash
helm list -n kyverno
```

Expected

```
NAME

kyverno
```

---

View release details

```bash
helm status kyverno -n kyverno
```

---

# Step 6 – Verify Pods

Run

```bash
kubectl get pods -n kyverno
```

Example output

```
NAME                                  READY

kyverno-admission-controller

kyverno-background-controller

kyverno-cleanup-controller

kyverno-reports-controller
```

Versions may differ.

---

# Understanding Each Pod

## Admission Controller

Purpose

Receives requests from Kubernetes API Server.

Responsibilities

* Validate resources
* Mutate resources
* Verify image signatures

This is the main Kyverno component.

---

## Background Controller

Runs continuously.

Checks existing resources.

Example

If a policy is added later,

Background Controller checks already existing Pods.

---

## Reports Controller

Creates

* Policy Reports
* ClusterPolicy Reports

Used by dashboards and compliance tools.

---

## Cleanup Controller

Automatically removes expired resources.

Useful for

* Temporary secrets
* Jobs
* Old resources

---

# Step 7 – Verify Services

```bash
kubectl get svc -n kyverno
```

Example

```
kyverno-svc
```

---

# Step 8 – Verify Deployments

```bash
kubectl get deploy -n kyverno
```

Expected

```
kyverno-admission-controller

kyverno-background-controller

kyverno-cleanup-controller

kyverno-reports-controller
```

---

# Step 9 – Verify ReplicaSets

```bash
kubectl get rs -n kyverno
```

Observe ReplicaSets created by Deployments.

---

# Step 10 – Verify Pods are Healthy

```bash
kubectl get pods -n kyverno -o wide
```

Observe

* Pod IP
* Node
* Status
* Restarts

Expected

```
Running

READY 1/1
```

---

# Step 11 – Describe Pod

Choose any pod

```bash
kubectl describe pod <pod-name> -n kyverno
```

Example

```bash
kubectl describe pod kyverno-admission-controller-xxxxx -n kyverno
```

Observe

* Image
* Events
* Mounted volumes
* Environment variables
* Service Account
* Resource limits

---

# Step 12 – View Logs

Admission Controller logs

```bash
kubectl logs deployment/kyverno-admission-controller -n kyverno
```

Or

```bash
kubectl logs <pod-name> -n kyverno
```

Observe

```
Starting Controller

Webhook registered

Ready
```

---

# Step 13 – Verify CRDs

Kyverno installs several Custom Resource Definitions.

List them

```bash
kubectl get crd | grep kyverno
```

Example

```
clusterpolicies.kyverno.io

policies.kyverno.io

policyreports

clusterpolicyreports
```

Discuss that these CRDs extend Kubernetes with new resource types used by Kyverno.

---

# Step 14 – Verify Webhooks

List all webhook configurations

```bash
kubectl get validatingwebhookconfigurations
```

Expected

```
kyverno-resource-validating-webhook-cfg
```

Now

```bash
kubectl get mutatingwebhookconfigurations
```

Expected

```
kyverno-resource-mutating-webhook-cfg
```

These webhook configurations are automatically registered with the Kubernetes API Server during installation.

---

# Step 15 – Inspect a Validating Webhook

```bash
kubectl describe validatingwebhookconfiguration
```

Observe

* Webhook name
* Rules
* Operations
* Failure Policy
* Service reference

Instructor Note: Explain that the **API Server** calls this webhook whenever matching resources are created, updated, or deleted.

---

# Step 16 – Inspect a Mutating Webhook

```bash
kubectl describe mutatingwebhookconfiguration
```

Observe

* Operations
* Resource types
* Admission review versions
* Client configuration

Explain that a mutating webhook can automatically modify objects before they are stored (for example, injecting labels or default values).

---

# Admission Controller – Deep Dive

An **Admission Controller** intercepts every request **after authentication and authorization but before the object is stored in etcd**.

Request Flow:

```
kubectl apply
       │
       ▼
Authentication
       │
       ▼
Authorization
       │
       ▼
Admission Controllers
       │
       ▼
Kyverno
       │
       ▼
etcd
```

If Kyverno rejects the request, the object is never created.

---

# Mutating Webhook

Purpose:

Automatically **changes** the incoming object.

Example:

Student deploys:

```yaml
labels:
  app: nginx
```

Kyverno can mutate it into:

```yaml
labels:
  app: nginx
  owner: platform-team
```

Other use cases:

* Add default labels
* Add annotations
* Inject sidecars
* Add imagePullSecrets
* Set resource requests/limits

Mutation occurs **before validation**.

---

# Validating Webhook

Purpose:

Checks whether the object complies with policy.

Example policy:

```
Containers must not run as root.
```

Student deploys:

```yaml
runAsUser: 0
```

Result:

```
Deployment Rejected
```

Validation **does not modify** the object; it only allows or denies it.

---

# Policy Engine

The Kyverno Policy Engine evaluates every request against all applicable policies.

Supported policy actions include:

* **Validate** – allow or reject resources.
* **Mutate** – modify resources before they are stored.
* **Generate** – automatically create related resources (for example, a NetworkPolicy when a Namespace is created).
* **Verify Images** – validate image signatures (for example, with Cosign).

---

# Step 17 – Verify Service Account

```bash
kubectl get sa -n kyverno
```

Expected

```
kyverno-admission-controller

kyverno-background-controller

kyverno-cleanup-controller

kyverno-reports-controller
```

Explain that each controller runs with its own ServiceAccount following the principle of least privilege.

---

# Step 18 – Verify Cluster Roles

```bash
kubectl get clusterrole | grep kyverno
```

Observe multiple ClusterRoles created for the different controllers.

---

# Step 19 – Verify Cluster Role Bindings

```bash
kubectl get clusterrolebinding | grep kyverno
```

These bind ServiceAccounts to the required ClusterRoles.

---

# Step 20 – Check Overall Resource Status

```bash
kubectl get all -n kyverno
```

Verify that:

* All Pods are **Running**
* Deployments are **Available**
* ReplicaSets are ready
* Services exist

---

# Cleanup (Optional)

If students need to remove Kyverno:

```bash
helm uninstall kyverno -n kyverno
```

Delete the namespace:

```bash
kubectl delete namespace kyverno
```

---

# Lab Validation Checklist

Students should verify the following:

* ✅ Helm repository added successfully.
* ✅ Kyverno installed using Helm.
* ✅ All Kyverno controller Pods are in the **Running** state.
* ✅ Services, Deployments, ReplicaSets, and ServiceAccounts are present.
* ✅ Kyverno CRDs have been installed.
* ✅ Mutating and Validating Webhook configurations exist.
* ✅ Admission Controller logs are accessible.

