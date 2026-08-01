

# Lab 10.4 – Enable Metrics Server on EKS Anywhere

## Objective

In this lab, you will:

* Install Metrics Server
* Verify metrics collection
* Enable resource monitoring
* Validate node and pod metrics
* Prepare the cluster for HPA and security monitoring

**Duration:** 20–30 Minutes

---

# Lab Architecture

```text
               kubectl top

                    │
                    ▼

            Metrics Server
                    │
      -----------------------------
      │                           │
      ▼                           ▼

   kubelet                    kubelet
 Control Plane              Worker Node
      │                           │
      ▼                           ▼

 CPU / Memory               CPU / Memory
```

---

# Step 1 – Verify Metrics Server

```bash
kubectl get deployment metrics-server -n kube-system
```

Expected

```text
Error from server (NotFound)
```

---

# Step 2 – Verify Metrics Are Unavailable

```bash
kubectl top nodes
```

Expected

```text
error: Metrics API not available
```

---

# Step 3 – Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

# Step 4 – Verify Installation

```bash
kubectl get pods -n kube-system
```

Expected

```text
metrics-server-xxxxxxxxxx
```

Wait until

```text
Running
```

---

# Step 5 – Check Deployment

```bash
kubectl get deployment metrics-server -n kube-system
```

Expected

```text
READY   UP-TO-DATE   AVAILABLE

1/1     1            1
```

---

# Step 6 – Verify API Registration

```bash
kubectl get apiservices
```

Expected

```text
v1beta1.metrics.k8s.io
```

Status

```text
True
```

---

# Step 7 – Test Metrics

```bash
kubectl top nodes
```

Expected

```text
NAME        CPU(cores)   CPU%

cp-01

worker-01
```

---

## Pod Metrics

```bash
kubectl top pods -A
```

Expected

```text
NAMESPACE      NAME

kube-system

argocd

nginx-demo
```

---

# Step 8 – If Metrics Are Not Available

Check logs

```bash
kubectl logs deployment/metrics-server -n kube-system
```

Typical error

```text
x509 certificate signed by unknown authority
```

---

# Step 9 – Patch Metrics Server (EKS Anywhere)

Most EKS Anywhere labs require adding the following arguments because kubelets use self-signed certificates.

Edit the deployment:

```bash
kubectl edit deployment metrics-server -n kube-system
```

Locate

```yaml
args:
```

Add:

```yaml
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP
```

Save and exit.

---

# Step 10 – Verify Rollout

```bash
kubectl rollout status deployment metrics-server -n kube-system
```

Expected

```text
deployment "metrics-server" successfully rolled out
```

---

# Step 11 – Verify Metrics Again

```bash
kubectl top nodes
```

Expected

```text
NAME          CPU(cores)   CPU%

cp-01         220m         11%

worker-01     140m          7%
```

---

# Step 12 – View Pod Metrics

```bash
kubectl top pods -A
```

Example

```text
NAMESPACE     POD                     CPU    MEMORY

argocd

metrics-server

nginx-demo
```

---

# Step 13 – Observe Resource Usage

Generate some traffic to the existing NGINX application.

Open another terminal:

```bash
kubectl run load-generator \
--image=busybox \
--restart=Never \
-n nginx-demo \
-- sh
```

Inside the Pod:

```sh
while true; do
    wget -q -O- http://nginx-service > /dev/null
done
```

---

Watch metrics update:

```bash
watch kubectl top pods -n nginx-demo
```

Observe CPU usage increase for the NGINX Pod.

Press **Ctrl+C** to stop watching.

---

# Step 14 – Clean Up

Delete the load generator:

```bash
kubectl delete pod load-generator -n nginx-demo
```

---

# Verification Checklist

| Task                        | Status |
| --------------------------- | ------ |
| Metrics Server Installed    | ✅      |
| Deployment Running          | ✅      |
| Metrics API Registered      | ✅      |
| `kubectl top nodes` Working | ✅      |
| `kubectl top pods` Working  | ✅      |
| CPU Metrics Visible         | ✅      |

---

# Learning Outcomes

Students should now understand:

* The Kubernetes **Metrics Server** collects CPU and memory metrics from kubelets.
* The `metrics.k8s.io` API enables commands like `kubectl top`.
* Metrics Server is **required for Horizontal Pod Autoscaler (HPA)**.
* It provides **near real-time resource usage**, not long-term monitoring.
* For production observability and security monitoring, Metrics Server is typically combined with **Prometheus** and **Grafana**.

---

## Troubleshooting Tips

| Problem                                         | Solution                                                        |
| ----------------------------------------------- | --------------------------------------------------------------- |
| `Metrics API not available`                     | Wait 1–2 minutes after installation.                            |
| `x509 certificate signed by unknown authority`  | Add `--kubelet-insecure-tls`.                                   |
| `No metrics returned from resource metrics API` | Verify kubelets are healthy and reachable.                      |
| `kubectl top` returns no data                   | Ensure `v1beta1.metrics.k8s.io` APIService is `Available=True`. |

This concise lab fits well before your HPA lab and establishes the monitoring foundation needed for autoscaling, runtime visibility, and later modules on observability and security.
