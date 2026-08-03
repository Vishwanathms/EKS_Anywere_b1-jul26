
# Lab 4 – Testing Kyverno Policy Enforcement

## Goal

Verify that Kyverno is functioning correctly by:

* Creating a policy
* Deploying a compliant application
* Deploying a non-compliant application
* Observing policy enforcement
* Viewing Kyverno logs

---

# Architecture

```text
kubectl apply
      │
      ▼
 Kubernetes API Server
      │
      ▼
Kyverno Admission Controller
      │
      ├── Policy Match?
      │
      ├── YES
      │      │
      │      ├── Allow
      │      └── Reject
      │
      ▼
 Object Stored in etcd
```

---

# Step 1 Verify Kyverno is Running

```bash
kubectl get pods -n kyverno
```

Expected

```
NAME                                     READY

kyverno-admission-controller              1/1

kyverno-background-controller             1/1

kyverno-cleanup-controller                1/1

kyverno-reports-controller                1/1
```

---

# Step 2 Create Test Namespace

```bash
kubectl create namespace kyverno-lab
```

Verify

```bash
kubectl get ns
```

---

# Step 3 Create Your First Policy

Create a file

```bash
nano require-label.yaml
```

Paste

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label

spec:
  validationFailureAction: Enforce

  background: true

  rules:

  - name: check-app-label

    match:
      any:
      - resources:
          kinds:
          - Pod

    validate:

      message: "Pods must have an app label."

      pattern:
        metadata:
          labels:
            app: "?*"
```

Save

Apply

```bash
kubectl apply -f require-label.yaml
```

Expected

```
clusterpolicy.kyverno.io/require-app-label created
```

---

# Step 4 Verify Policy

```bash
kubectl get clusterpolicy
```

Expected

```
NAME

require-app-label
```

Describe it

```bash
kubectl describe clusterpolicy require-app-label
```

Observe

* Rule
* Match
* Validation
* Message

---

# Step 5 Deploy a Valid Pod

Create

```bash
nano good-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx-good

  namespace: kyverno-lab

  labels:
    app: nginx

spec:

  containers:

  - name: nginx

    image: nginx
```

Deploy

```bash
kubectl apply -f good-pod.yaml
```

Expected

```
pod/nginx-good created
```

Verify

```bash
kubectl get pods -n kyverno-lab
```

Expected

```
nginx-good

Running
```

---

# Step 6 Deploy an Invalid Pod

Create

```bash
nano bad-pod.yaml
```

```yaml
apiVersion: v1

kind: Pod

metadata:

  name: nginx-bad

  namespace: kyverno-lab

spec:

  containers:

  - name: nginx

    image: nginx
```

Notice

There is **NO app label**.

Deploy

```bash
kubectl apply -f bad-pod.yaml
```

Expected

```
Error from server:

admission webhook

validate.kyverno.svc

denied the request

Pods must have an app label.
```

Congratulations!

Kyverno has successfully intercepted the API request.

---

# Step 7 Verify Only One Pod Exists

```bash
kubectl get pods -n kyverno-lab
```

Expected

```
nginx-good

Running
```

The second pod never entered the cluster.

---

# Step 8 View Kyverno Logs

Find the Admission Controller

```bash
kubectl get pods -n kyverno
```

View logs

```bash
kubectl logs deployment/kyverno-admission-controller -n kyverno
```

or

```bash
kubectl logs <pod-name> -n kyverno
```

Observe

```
Admission Review

Policy Evaluated

Validation Failed

Request Denied
```

---

# Step 9 Describe the Policy

```bash
kubectl describe clusterpolicy require-app-label
```

Observe

* Rules
* Status
* Ready
* Age

---

# Step 10 View Policy Reports

```bash
kubectl get policyreport -A
```

or

```bash
kubectl get clusterpolicyreport
```

Depending on your Kyverno version, you'll see policy report resources indicating pass/fail evaluations.

---

# Step 11 Test Using kubectl run

Without label

```bash
kubectl run test1 \
--image=nginx \
-n kyverno-lab
```

Expected

```
Denied
```

With label

```bash
kubectl run test2 \
--image=nginx \
-n kyverno-lab \
--labels app=nginx
```

Expected

```
pod/test2 created
```

---

# Understanding the Flow

## Successful Request

```
kubectl apply
        │
        ▼
API Server
        │
        ▼
Kyverno

Policy Passed
        │
        ▼
Pod Created
```

---

## Failed Request

```
kubectl apply
        │
        ▼
API Server
        │
        ▼
Kyverno

Policy Failed
        │
        ▼
Request Rejected
```

The Pod is **never written to etcd**, which is exactly how admission control is intended to work.

---

# Bonus Experiment 1 – Audit Mode

Change the policy:

```yaml
validationFailureAction: Audit
```

Apply it again:

```bash
kubectl apply -f require-label.yaml
```

Now create the invalid Pod again:

```bash
kubectl apply -f bad-pod.yaml
```

This time:

* ✅ Pod is created.
* ⚠️ A policy violation is recorded in the policy report.

This demonstrates the difference between **Audit** and **Enforce** modes.

---

# Bonus Experiment 2 – Test an Existing Pod

After switching to `Audit`, create several Pods and then run:

```bash
kubectl get policyreport -A
```

Students can observe how the **Background Controller** evaluates existing resources and records violations.

---

# Cleanup

```bash
kubectl delete namespace kyverno-lab

kubectl delete clusterpolicy require-app-label
```

---

# Expected Learning Outcomes

By the end of this lab, students will have demonstrated that Kyverno is functioning correctly by:

* Installing and verifying the Kyverno controllers.
* Creating and applying a `ClusterPolicy`.
* Understanding the difference between **Audit** and **Enforce** modes.
* Successfully deploying a compliant Pod.
* Observing a non-compliant Pod being rejected by the **Validating Admission Webhook**.
* Viewing Kyverno logs and policy reports to understand how admission requests are processed.

This is an ideal first validation exercise before moving to more realistic policies, such as:

1. **Disallow `:latest` image tags** (very common in production).
2. **Require CPU and memory requests/limits**.
3. **Block privileged containers**.
4. **Enforce `runAsNonRoot: true`**.
5. **Restrict images to approved registries** (e.g., ECR, ACR, or Harbor).

These scenarios closely match the types of policies implemented in enterprise Kubernetes environments.
