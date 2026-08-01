# LAB 10.2 – Kubernetes User RBAC (kubectl User)

This lab demonstrates how Kubernetes authenticates external users using client certificates.

**Duration:** 90 Minutes

---

## Objective

Students learn

* Create user certificate
* Generate kubeconfig
* Create Role
* Bind user
* Login as user
* Test permissions

---

# Architecture

```
Laptop

kubectl
    |
    |  kubeconfig
    |
Client Certificate

        |

 Kubernetes API Server

        |

Authentication

        |

Authorization

        |

Role

        |

RoleBinding
```

---

# Step 1 Create Private Key

```
mkdir student1

cd student1
```

Generate key

```
openssl genrsa -out student1.key 2048
```

---

# Step 2 Create CSR

```
openssl req -new \
-key student1.key \
-out student1.csr \
-subj "/CN=student1/O=students"
```

Explain

CN = username

O = group

---

# Step 3 Sign Certificate

On the EKS Anywhere control plane node, locate the Kubernetes CA:

```
sudo ls /etc/kubernetes/pki
```

Typical files:

```
ca.crt
ca.key
```

Sign the CSR:

```bash
sudo openssl x509 -req \
-in student1.csr \
-CA /etc/kubernetes/pki/ca.crt \
-CAkey /etc/kubernetes/pki/ca.key \
-CAcreateserial \
-out student1.crt \
-days 365
```

Verify

```
openssl x509 -in student1.crt -text
```

---

# Step 4 Create Role

```
student-role.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:

  namespace: nginx-demo

  name: student-reader

rules:

- apiGroups: [""]

  resources:

  - pods

  - services

  verbs:

  - get

  - list

  - watch
```

Deploy

```
kubectl apply -f student-role.yaml
```

---

# Step 5 Create RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1

kind: RoleBinding

metadata:

  namespace: nginx-demo

  name: student1-binding

subjects:

- kind: User

  name: student1

roleRef:

  kind: Role

  name: student-reader

  apiGroup: rbac.authorization.k8s.io
```

Deploy

```
kubectl apply -f rolebinding.yaml
```

---

# Step 6 Build kubeconfig

Get cluster details:

```bash
kubectl config view --minify
```

Extract:

* Cluster name
* API server endpoint
* CA certificate

Set cluster:

```bash
kubectl config set-cluster eks-anywhere \
  --server=https://<API_SERVER>:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --kubeconfig=student1.kubeconfig
```

Set user:

```bash
kubectl config set-credentials student1 \
  --client-certificate=student1.crt \
  --client-key=student1.key \
  --embed-certs=true \
  --kubeconfig=student1.kubeconfig
```

Set context:

```bash
kubectl config set-context student1-context \
  --cluster=eks-anywhere \
  --user=student1 \
  --namespace=nginx-demo \
  --kubeconfig=student1.kubeconfig
```

Use the context:

```bash
kubectl config use-context student1-context \
  --kubeconfig=student1.kubeconfig
```

View the generated kubeconfig:

```bash
kubectl config view --kubeconfig=student1.kubeconfig
```

---

# Step 7 Test Access

Using the new kubeconfig:

```bash
kubectl get pods \
  --kubeconfig=student1.kubeconfig
```

Expected: Success.

Check permissions:

```bash
kubectl auth can-i get pods \
  --kubeconfig=student1.kubeconfig
```

Expected:

```
yes
```

Try a forbidden operation:

```bash
kubectl delete pod <pod-name> \
  --kubeconfig=student1.kubeconfig
```

Expected:

```
Error from server (Forbidden)
```

Try listing secrets:

```bash
kubectl get secrets \
  --kubeconfig=student1.kubeconfig
```

Expected:

```
Forbidden
```

---

# Step 8 Experiment with Roles

Modify the `student-reader` role to:

* Add `configmaps`
* Add `deployments` (using `apiGroups: ["apps"]`)
* Add `update`
* Add `patch`

After each change, re-run:

```bash
kubectl auth can-i --list \
  --kubeconfig=student1.kubeconfig
```

Observe how effective permissions change immediately after the Role is updated.

---

# Step 9 Cleanup

```bash
kubectl delete role student-reader -n nginx-demo
kubectl delete rolebinding student1-binding -n nginx-demo
rm -f student1.key student1.csr student1.crt student1.kubeconfig
```

-