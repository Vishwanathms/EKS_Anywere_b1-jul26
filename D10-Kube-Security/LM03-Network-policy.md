---

# Lab 10.4 – Secure Workloads Using Kubernetes Network Policies

## Objective

In this lab students will learn how Kubernetes Network Policies control communication between Pods.

By the end of this lab students will be able to:

* Understand Kubernetes networking
* Understand Pod-to-Pod communication
* Create labels for policy targeting
* Restrict ingress traffic
* Restrict egress traffic
* Verify blocked traffic
* Restore communication
* Understand Zero Trust networking

---

# Lab Architecture

```
                 nginx-demo Namespace
+------------------------------------------------------+

        frontend Pod  --------> nginx Pod
              |                    |
              |                    |
              +------> busybox ----+

Initially
---------
Everyone can talk to everyone.

After Policy
------------

frontend -----> nginx      (Allowed)

busybox  ----X nginx        (Denied)

Outside Namespace ----X nginx
```

---

# Lab Duration

**45–60 Minutes**

---

# Prerequisites

Students already completed:

* Helm Deployment Lab
* nginx-demo namespace
* NGINX Service
* kubectl configured

---

# Step 1 – Verify Existing Deployment

```
kubectl get all -n nginx-demo
```

Expected

```
NAME                          READY
pod/nginx-xxxxx               1/1
service/nginx-service
deployment.apps/nginx
```

---

# Step 2 – Create Test Client Pods

We'll create two client Pods.

## frontend Pod

```
kubectl run frontend \
--image=busybox \
--labels=app=frontend \
-n nginx-demo \
-- sleep 36000
```

---

## busybox Pod

```
kubectl run busybox \
--image=busybox \
--labels=app=busybox \
-n nginx-demo \
-- sleep 36000
```

Verify

```
kubectl get pods -n nginx-demo
```

Expected

```
frontend
busybox
nginx
```

---

# Step 3 – Test Current Connectivity

Enter frontend

```
kubectl exec -it frontend -n nginx-demo -- sh
```

Inside

```
wget -qO- http://nginx-service
```

Expected

```
Welcome to nginx!
```

Exit

```
exit
```

---

Now test from busybox

```
kubectl exec -it busybox -n nginx-demo -- sh
```

```
wget -qO- http://nginx-service
```

Expected

```
Welcome to nginx!
```

Observation

Everyone can reach nginx.

---

# Step 4 – Understand Why

By default Kubernetes networking behaves like:

```
Allow All
```

Every Pod can communicate with every other Pod.

There is no firewall.

There is no isolation.

---

# Step 5 – Label the NGINX Pod

Check labels

```
kubectl get pods \
-n nginx-demo \
--show-labels
```

Example

```
app=nginx
```

If not present

```
kubectl label pod nginx-xxxxx app=nginx
```

---

# Step 6 – Create First Network Policy

Create

```
networkpolicy-ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy

metadata:
  name: allow-frontend

  namespace: nginx-demo

spec:

  podSelector:

    matchLabels:
      app: nginx

  policyTypes:

  - Ingress

  ingress:

  - from:

    - podSelector:

        matchLabels:

          app: frontend
```

Apply

```
kubectl apply -f networkpolicy-ingress.yaml
```

---

# Step 7 – Verify Policy

```
kubectl get networkpolicy -n nginx-demo
```

Expected

```
allow-frontend
```

---

# Step 8 – Test from Frontend

```
kubectl exec -it frontend -n nginx-demo -- sh
```

```
wget -qO- http://nginx-service
```

Expected

```
Welcome to nginx!
```

Success

---

# Step 9 – Test from Busybox

```
kubectl exec -it busybox -n nginx-demo -- sh
```

```
wget -T 5 -qO- http://nginx-service
```

Expected

```
Connection timed out
```

Busybox cannot reach nginx anymore.

---

# Step 10 – Explain What Happened

Network Policy selected

```
app=nginx
```

Only Pods with

```
app=frontend
```

can access nginx.

Everyone else

```
DENIED
```

---

# Step 11 – Verify Using Curl

Instead of BusyBox wget you can launch

```
kubectl run curl \
--image=curlimages/curl \
--restart=Never \
-n nginx-demo \
-- sleep 36000
```

Test

```
kubectl exec -it curl -n nginx-demo -- sh
```

```
curl nginx-service
```

Expected

```
Connection timed out
```

---

# Step 12 – Observe Policy

Describe

```
kubectl describe networkpolicy allow-frontend \
-n nginx-demo
```

Students should identify

```
Pod Selector

Ingress Rules

Allowed Labels

Policy Type
```

---

# Step 13 – Restrict Egress

Now demonstrate outbound control.

Create

```
networkpolicy-egress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy

metadata:
  name: restrict-egress

  namespace: nginx-demo

spec:

  podSelector:

    matchLabels:

      app: frontend

  policyTypes:

  - Egress

  egress:

  - to:

    - podSelector:

        matchLabels:

          app: nginx
```

Apply

```
kubectl apply -f networkpolicy-egress.yaml
```

---

# Step 14 – Verify Egress

Enter frontend

```
kubectl exec -it frontend -n nginx-demo -- sh
```

Try

```
wget google.com
```

Expected

```
Failed
```

Now try

```
wget -qO- http://nginx-service
```

Expected

```
Welcome to nginx!
```

---

# Step 15 – Delete Policy

```
kubectl delete networkpolicy allow-frontend \
-n nginx-demo

kubectl delete networkpolicy restrict-egress \
-n nginx-demo
```

---

# Step 16 – Verify Communication Restored

Busybox

```
kubectl exec -it busybox -n nginx-demo -- sh
```

```
wget -qO- http://nginx-service
```

Expected

```
Welcome to nginx!
```

Traffic restored.

---

# Understanding the Traffic Flow

## Before Policy

```
Frontend --------> nginx

Busybox ---------> nginx

Curl ------------> nginx

Any Namespace ---> nginx
```

All communication is allowed.

---

## After Ingress Policy

```
Frontend --------> nginx   ✓

Busybox --------X nginx

Curl ----------->X nginx

Other Namespace->X nginx
```

Only the `frontend` Pod is permitted to access the NGINX Pods.

---

## After Egress Policy

```
Frontend ---> nginx ✓

Frontend ---> Internet X

Frontend ---> Busybox X

Frontend ---> DNS X (unless explicitly allowed)
```

This demonstrates that egress policies apply a **default-deny** model for outbound traffic unless destinations are explicitly permitted. In production, you would typically add rules to allow DNS (UDP/TCP 53 to CoreDNS) and any required external services.

---

# Discussion

Students should understand the following key concepts:

| Concept                       | Description                                                                |
| ----------------------------- | -------------------------------------------------------------------------- |
| Default Kubernetes Networking | Every Pod can communicate with every other Pod unless restricted.          |
| NetworkPolicy                 | Acts as a Layer 3/Layer 4 firewall for Pods.                               |
| podSelector                   | Identifies which Pods the policy applies to.                               |
| ingress                       | Controls incoming connections to selected Pods.                            |
| egress                        | Controls outgoing connections from selected Pods.                          |
| policyTypes                   | Specifies whether the policy governs Ingress, Egress, or both.             |
| Zero Trust                    | Only explicitly allowed traffic is permitted; all other traffic is denied. |

---

# Production Considerations

For production-grade clusters, discuss these additional best practices:

* Use a **default-deny NetworkPolicy** in every namespace before adding allow rules.
* Apply policies to all application namespaces, not just internet-facing workloads.
* Combine NetworkPolicies with **RBAC**, **Pod Security Standards**, and **service accounts** for defense in depth.
* Be aware that **NetworkPolicies are enforced only if the CNI plugin supports them** (e.g., Cilium, Calico, Antrea). Ensure your EKS Anywhere cluster uses a compatible CNI.
* Explicitly allow DNS, metrics, logging, and other required infrastructure traffic when using egress restrictions.

This lab naturally follows your RBAC and Service Account exercises and prepares students for the subsequent topics on **Pod Security Standards**, **Runtime Security**, and **Policy as Code** by introducing network-level Zero Trust controls.
