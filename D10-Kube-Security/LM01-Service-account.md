Yes. For your **EKS Anywhere + ArgoCD** course, RBAC is one of the most important security labs because students need to understand the difference between:

1. **Service Account RBAC** (Applications running inside Kubernetes)
2. **User RBAC** (Humans using kubectl)

These should be two completely separate labs.

---

# LAB 1 – Kubernetes RBAC using Service Account

**Module 10 – Kubernetes Security**

**Lab Duration:** 60-75 Minutes

## Objective

In this lab students will learn

* Create a Service Account
* Understand Service Account Tokens
* Create Role
* Create RoleBinding
* Verify permissions
* Access Kubernetes API
* Test allowed operations
* Test denied operations
* Understand Least Privilege

---

# Architecture

```
                    Kubernetes Cluster

               +-------------------------+
               |                         |
               | nginx-demo namespace    |
               |                         |
               |  nginx deployment       |
               |  nginx pods             |
               |                         |
               +------------+------------+
                            ^
                            |
                   Role + RoleBinding
                            |
                  ServiceAccount
                            |
                 Debug/Test Pod
```

---

# Prerequisites

Cluster running

```
kubectl get nodes
```

ArgoCD deployed

Existing namespace

```
nginx-demo
```

Deployment

```
kubectl get deploy -n nginx-demo
```

Pods

```
kubectl get pods -n nginx-demo
```

Expected

```
NAME
nginx-demo-xxxxx
```

---

# Step 1 Create Service Account

```
kubectl create namespace rbac-lab
```

```
kubectl create serviceaccount app-reader -n rbac-lab
```

Verify

```
kubectl get sa -n rbac-lab
```

Expected

```
NAME
app-reader
default
```

---

# Step 2 Create Debug Pod

Create

```
pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-test
  namespace: rbac-lab

spec:
  serviceAccountName: app-reader

  containers:

  - name: kubectl

    image: bitnami/kubectl:latest

    command:

    - sleep

    - "36000"
```

Deploy

```
kubectl apply -f pod.yaml
```

Verify

```
kubectl get pods -n rbac-lab
```

---

# Step 3 Login into Pod

```
kubectl exec -it api-test -n rbac-lab -- sh
```

---

# Step 4 Verify Token

Inside pod

```
ls

/var/run/secrets/kubernetes.io/serviceaccount
```

Output

```
ca.crt

namespace

token
```

Display namespace

```
cat namespace
```

Display token

```
cat token
```

Observe JWT token.

Explain

* Automatically mounted
* Short lived
* Bound to Service Account

---

# Step 5 Test Current Permission

Inside pod

```
kubectl auth can-i get pods -n nginx-demo
```

Expected

```
no
```

Try

```
kubectl get pods -n nginx-demo
```

Expected

```
Forbidden
```

Explain

No RBAC assigned.

---

# Step 6 Create Role

Outside pod

```
role.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  namespace: nginx-demo
  name: pod-reader

rules:

- apiGroups: [""]

  resources:

  - pods

  verbs:

  - get

  - list

  - watch
```

Deploy

```
kubectl apply -f role.yaml
```

---

# Step 7 Create RoleBinding

```
rolebinding.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:

  namespace: nginx-demo

  name: pod-reader-binding

subjects:

- kind: ServiceAccount

  name: app-reader

  namespace: rbac-lab

roleRef:

  apiGroup: rbac.authorization.k8s.io

  kind: Role

  name: pod-reader
```

Deploy

```
kubectl apply -f rolebinding.yaml
```

---

# Step 8 Test Again

Login

```
kubectl exec -it api-test -n rbac-lab -- sh
```

Test

```
kubectl auth can-i get pods -n nginx-demo
```

Expected

```
yes
```

Now

```
kubectl get pods -n nginx-demo
```

Expected

Pods listed successfully.

---

# Step 9 Try Forbidden Operations

Delete Pod

```
kubectl delete pod xxx -n nginx-demo
```

Expected

```
Forbidden
```

Create Pod

```
kubectl run nginx --image=nginx -n nginx-demo
```

Forbidden

Scale deployment

```
kubectl scale deploy nginx-demo --replicas=5 -n nginx-demo
```

Forbidden

---

# Step 10 Check Permissions

```
kubectl auth can-i --list
```

Students can observe

```
pods

list

watch

get
```

Nothing else.

---

# Step 11 Expand Permissions

Modify Role

Add

```yaml
resources:

- services
```

Now test

```
kubectl get svc -n nginx-demo
```

Works

---

# Step 12 Read ConfigMaps

Add

```yaml
resources:

- configmaps
```

Verify

```
kubectl get configmaps -n nginx-demo
```

---

# Step 13 Try Secrets

```
kubectl get secrets
```

Forbidden

Discuss why Secrets should not be exposed.

---

# Step 14 Cleanup

```
kubectl delete namespace rbac-lab

kubectl delete role pod-reader -n nginx-demo

kubectl delete rolebinding pod-reader-binding -n nginx-demo
```

---

# Learning Outcome

Students understand

* Service Account
* JWT Token
* Kubernetes API Authentication
* Authorization
* Role
* RoleBinding
* Least Privilege

---

