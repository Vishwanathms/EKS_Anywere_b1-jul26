# Lab 1 – Deploy an NGINX Application on Amazon EKS Anywhere

## Objective

In this lab, you will:

* Create an NGINX Deployment
* Expose it using a NodePort Service
* Verify Pods and Service
* Access the application from a web browser using the worker node IP and NodePort

---

# Lab Topology

```
                Browser
                   |
                   |
        http://<Worker-Node-IP>:30080
                   |
           +-------------------+
           |  NodePort Service |
           |      30080        |
           +-------------------+
                   |
            Kubernetes Service
                   |
          +------------------+
          |  NGINX Pods      |
          |   Deployment     |
          +------------------+
```

---

# Prerequisites

Ensure the following:

* EKS Anywhere cluster is running
* kubectl is configured
* Worker nodes are in Ready state

Verify:

```bash
kubectl get nodes
```

Example:

```
NAME                    STATUS   ROLES
production-cp-01        Ready    control-plane
production-worker-01    Ready    worker
```

---

# Step 1 – Create a Working Directory

```bash
mkdir nginx-lab
cd nginx-lab
```

---

# Step 2 – Create Deployment YAML

Create a file named:

```
nginx-deployment.yaml
```

Paste the following:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2

  selector:
    matchLabels:
      app: nginx

  template:
    metadata:
      labels:
        app: nginx

    spec:
      containers:
      - name: nginx
        image: nginx:latest

        ports:
        - containerPort: 80
```

---

# Step 3 – Create NodePort Service

Create

```
nginx-service.yaml
```

Paste:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service

spec:
  selector:
    app: nginx

  type: NodePort

  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

---

# Step 4 – Deploy the Application

Create the deployment.

```bash
kubectl apply -f nginx-deployment.yaml
```

Expected:

```
deployment.apps/nginx-deployment created
```

---

Create the service.

```bash
kubectl apply -f nginx-service.yaml
```

Expected

```
service/nginx-service created
```

---

# Step 5 – Verify Deployment

Check deployments

```bash
kubectl get deployments
```

Example

```
NAME               READY   UP-TO-DATE   AVAILABLE
nginx-deployment   2/2     2            2
```

---

Check ReplicaSet

```bash
kubectl get rs
```

---

Check Pods

```bash
kubectl get pods -o wide
```

Example

```
NAME                                READY   STATUS    IP            NODE
nginx-deployment-5c89d7b44d-abc12   1/1     Running   10.10.1.12    worker-01
nginx-deployment-5c89d7b44d-def45   1/1     Running   10.10.2.18    worker-02
```

Observe:

* Pod Name
* Pod IP
* Worker Node
* Status

---

# Step 6 – Verify the Service

```bash
kubectl get svc
```

Example

```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx-service    NodePort   10.96.120.101   <none>        80:30080/TCP
```

Notice

```
80:30080/TCP
```

This means

* Service Port = 80
* NodePort = 30080

---

# Step 7 – Describe the Service

```bash
kubectl describe svc nginx-service
```

Look for

```
Selector:
app=nginx

Endpoints:
10.244.0.20:80
10.244.1.21:80
```

Endpoints indicate the Pods receiving traffic.

---

# Step 8 – Get the Worker Node IP

Display nodes

```bash
kubectl get nodes -o wide
```

Example

```
NAME                INTERNAL-IP
cp-01               192.168.100.50
worker-01           192.168.100.60
worker-02           192.168.100.61
```

Use the IP address of **any worker node**.

Example

```
192.168.100.60
```

---

# Step 9 – Test from the Cluster

Run

```bash
curl http://192.168.100.60:30080
```

Expected

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

---

# Step 10 – Access from a Browser

Open a browser on your laptop or any machine that has network connectivity to the EKS Anywhere worker nodes.

Enter the URL:

```
http://<Worker-Node-IP>:30080
```

Example:

```
http://192.168.100.60:30080
```

or

```
http://192.168.100.61:30080
```

You should see the default **Welcome to nginx!** page.

**Note:** If the page does not load, verify the following:

* The browser can reach the worker node network.
* TCP port **30080** is allowed by any firewall or pfSense rules.
* The NodePort service exists (`kubectl get svc`).
* The NGINX pods are in the `Running` state (`kubectl get pods`).

---

# Step 11 – Verify Load Balancing

Refresh the browser several times or execute:

```bash
for i in {1..10}
do
curl http://192.168.100.60:30080
done
```

Since the default NGINX page is identical on each pod, the output will look the same. To visibly demonstrate load balancing in a later lab, you can customize each pod's web page to display its hostname.

---

# Step 12 – Delete the Resources

Delete the service

```bash
kubectl delete -f nginx-service.yaml
```

Delete the deployment

```bash
kubectl delete -f nginx-deployment.yaml
```

Verify

```bash
kubectl get all
```

The NGINX deployment and service should no longer be present.

---

# Verification Checklist

| Task                                    | Status |
| --------------------------------------- | ------ |
| Deployment created                      | ☐      |
| Two Pods running                        | ☐      |
| NodePort Service created                | ☐      |
| Service listening on port 30080         | ☐      |
| Worker node IP identified               | ☐      |
| Browser displays the NGINX welcome page | ☐      |
| Resources deleted successfully          | ☐      |

### Browser Access Summary

```text
kubectl get svc
```

Example output:

```
NAME            TYPE       CLUSTER-IP      PORT(S)
nginx-service   NodePort   10.96.120.101   80:30080/TCP
```

```text
kubectl get nodes -o wide
```

Example output:

```
worker-01    Ready    192.168.100.60
```

Open your browser and navigate to:

```
http://192.168.100.60:30080
```

