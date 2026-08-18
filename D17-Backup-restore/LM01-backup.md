## Module – Backup & Disaster Recovery with Velero on EKS Anywhere

### Lab objectives

By the end of the lab, students should be able to:

* Install Velero on an EKS Anywhere cluster
* Configure an **on-premises S3-compatible backup repository**
* Back up Kubernetes resources
* Back up application data stored in PVCs
* Restore an entire namespace
* Restore persistent-volume data
* Verify application recovery
* Understand the difference between:

  * Kubernetes object backup
  * PV snapshot
  * File-system backup
  * Full cluster disaster recovery

### Recommended architecture for your EKS Anywhere lab

Since your EKS Anywhere environment is on **vSphere**, don't make AWS S3 the only option.

I recommend:

```text
                 Student Admin VM
                       |
                       | kubectl / velero CLI
                       |
                +------v-------+
                | EKS Anywhere |
                |   Cluster    |
                +------+-------+
                       |
          +------------+-------------+
          |                          |
     Applications                 Velero
          |                          |
     PVC / PV                       |
          |                          |
          +------------+-------------+
                       |
                       v
              +----------------+
              | MinIO          |
              | S3 Compatible  |
              | Object Storage  |
              +----------------+
                       |
                    Backup
```

This is particularly appropriate for your environment because you have already been working with **MinIO on EKS Anywhere**.

Velero supports on-premises environments and uses object storage as its backup storage location. ([Velero][2])

---

# Part 1 – Prepare the Lab

## 1. Check the EKS Anywhere cluster

On the student's admin machine:

```bash
kubectl config current-context
```

Check nodes:

```bash
kubectl get nodes -o wide
```

Check Kubernetes version:

```bash
kubectl version
```

Check storage:

```bash
kubectl get storageclass
```

Check existing PVCs:

```bash
kubectl get pvc -A
```

For the lab, students should have a working StorageClass and dynamic PVC provisioning.

For example:

```text
NAME                   PROVISIONER
vsphere-csi            csi.vsphere.vmware.com
```

The exact StorageClass name will depend on your EKS Anywhere/vSphere configuration.

---

# Part 2 – Create a Test Application

Don't immediately back up the entire cluster.

First create a small application that gives students something meaningful to destroy and recover.

Create namespace:

```bash
kubectl create namespace backup-demo
```

Create a PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
  namespace: backup-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: YOUR_STORAGE_CLASS
  resources:
    requests:
      storage: 5Gi
```

Apply:

```bash
kubectl apply -f pvc.yaml
```

Check:

```bash
kubectl get pvc -n backup-demo
```

Expected:

```text
NAME       STATUS   VOLUME
demo-pvc   Bound    pvc-xxxxxxxx
```

---

# Part 3 – Deploy an Application

Use a simple NGINX application.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backup-demo
  namespace: backup-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backup-demo
  template:
    metadata:
      labels:
        app: backup-demo
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: demo-pvc
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

Check:

```bash
kubectl get pods -n backup-demo
```

---

# Part 4 – Put Important Data into the PV

This is important.

Students need to see that **the Kubernetes object and the actual application data are two different things**.

Get into the pod:

```bash
kubectl exec -it -n backup-demo \
  deploy/backup-demo -- bash
```

Create data:

```bash
echo "EKS Anywhere Velero Backup Lab" \
> /usr/share/nginx/html/index.html

echo "Student backup test" \
> /usr/share/nginx/html/student.txt

exit
```

Verify:

```bash
kubectl exec -n backup-demo \
  deploy/backup-demo -- cat /usr/share/nginx/html/student.txt
```

Expected:

```text
Student backup test
```

---
