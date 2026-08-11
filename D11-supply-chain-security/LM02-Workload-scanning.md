Lab 2 – Scan Existing Kubernetes Workloads

Instead of scanning images from Docker Hub only.

Students inspect their own cluster.

Examples

```bash
kubectl get pods -A
```

Scan running workloads

```bash
trivy k8s cluster

```
Scan namespace

```bash
trivy k8s namespace nginx-demo
```