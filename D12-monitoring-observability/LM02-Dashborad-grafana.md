--

# Lab 12 – Exercise 2

# Monitoring Applications, Dashboards and Alerts

**Duration:** 60–75 Minutes

---

# Objective

In this exercise you will

* Deploy a sample web application
* Expose it inside the Kubernetes cluster
* Generate continuous traffic
* Observe resource utilization in Grafana
* Create a custom dashboard
* Configure a CPU utilization alert
* Verify the alert by generating additional load

---

# Architecture

```text
User Traffic
      │
      ▼
Load Generator Pod
      │
      ▼
Nginx Web Application
      │
      ▼
Kubernetes Cluster
      │
      ▼
Prometheus
      │
      ▼
Grafana Dashboard
      │
      ▼
Alert Manager
```

---

# Prerequisites

Before beginning this exercise, verify

✔ Prometheus Stack Installed

✔ Grafana Accessible

✔ Prometheus Targets Healthy

✔ Monitoring Namespace Exists

---

# Task 7

# Deploy a Sample Application

---

## Why?

Monitoring is useful only when applications are running.

Instead of monitoring an idle Kubernetes cluster, we will deploy a simple web application and observe its resource usage.

---

## Step 1

### Create Namespace

Although you already have a monitoring namespace, applications should run in their own namespace.

Create one called **demo**.

```bash
kubectl create namespace demo
```

Verify

```bash
kubectl get ns
```

Expected

```
demo
monitoring
default
```

---

## Step 2

### Deploy Nginx

Deploy a simple Nginx application.

```bash
kubectl create deployment nginx-demo \
--image=nginx:latest \
-n demo
```

---

Verify

```bash
kubectl get pods -n demo
```

Expected

```
nginx-demo-xxxxxxxx
Running
```

---

## Step 3

### Expose the Application

Create a ClusterIP Service.

```bash
kubectl expose deployment nginx-demo \
--port=80 \
--target-port=80 \
--type=ClusterIP \
-n demo
```

Verify

```bash
kubectl get svc -n demo
```

Expected

```
nginx-demo
ClusterIP
```

---

## Step 4

### Verify Application

Port forward

```bash
kubectl port-forward svc/nginx-demo 8080:80 -n demo
```

Open browser

```
http://localhost:8080
```

You should see

```
Welcome to nginx!
```

Stop the port forward after verification.

---

# Task 7A

# Generate Continuous Traffic

---

## Why?

Without application traffic, dashboards remain mostly idle.

We need continuous requests to generate observable metrics.

---

## Step 1

Create a temporary BusyBox Pod.

```bash
kubectl run load-generator \
--image=busybox \
-it \
--rm \
-n demo \
-- sh
```

Inside the pod install wget (if needed) or use the built-in `wget`.

---

## Step 2

Run an infinite loop.

```sh
while true
do
wget -q -O- http://nginx-demo
sleep 0.2
done
```

The Pod continuously sends requests.

Leave this terminal running.

---

## Step 3

Open another terminal.

Verify Pods

```bash
kubectl get pods -n demo
```

---

The application is now receiving continuous requests.

---

# Task 8

# Observe Metrics in Grafana

---

## Step 1

Open Grafana.

```
http://localhost:3000
```

Login

```
admin
```

---

## Step 2

Open

```
Dashboards

↓

Browse
```

---

## Step 3

Open the dashboard

```
Kubernetes

↓

Compute Resources

↓

Namespace
```

---

Select Namespace

```
demo
```

Observe

* CPU

* Memory

* Network

* Running Pods

---

## Step 4

Increase the dashboard time

```
Last 5 Minutes
```

Observe

Graphs continuously changing.

---

## Step 5

Stop the BusyBox Pod.

Observe

CPU decreases.

Request rate decreases.

Students should understand

Metrics change in real time.

---

# Task 8A

# Create a Custom Dashboard

---

## Why?

Operations teams create dashboards specific to their applications.

---

## Step 1

Grafana

```
Dashboards

↓

New Dashboard
```

---

## Step 2

Click

```
Add Visualization
```

Select

```
Prometheus
```

---

## Step 3

Create Panel 1

Title

```
CPU Usage
```

Query

```
sum(rate(container_cpu_usage_seconds_total[5m]))
```

---

## Step 4

Create Panel 2

```
Memory Usage
```

Query

```
sum(container_memory_working_set_bytes)
```

---

## Step 5

Create Panel 3

```
Running Pods
```

Query

```
count(kube_pod_info)
```

---

## Step 6

Create Panel 4

```
Pod Restart Count
```

Query

```
sum(kube_pod_container_status_restarts_total)
```

---

## Step 7

Save Dashboard

Name

```
Student Monitoring Dashboard
```

---

Students should now have their own dashboard.

---
