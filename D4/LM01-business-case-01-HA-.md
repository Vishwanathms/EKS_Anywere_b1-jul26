students already have a production cluster consisting of:

| Node Type     | Count | Purpose                                              |
| ------------- | ----: | ---------------------------------------------------- |
| Control Plane |     2 | Kubernetes API Server, Scheduler, Controller Manager |
| Worker Nodes  |     2 | Application workloads                                |
| External ETCD |     3 | Cluster datastore                                    |

This is an ideal setup to demonstrate how production clusters isolate workloads using labels, taints, tolerations, affinity rules, and resource management.

---

# Lab 3

# Production Cluster Design

## Objective

In this lab students will design a production-grade Kubernetes scheduling strategy by creating dedicated node pools and deploying applications using scheduling policies.

By the end of this lab students will be able to

* Understand production node segregation
* Label worker nodes
* Apply taints
* Configure tolerations
* Use node selectors
* Configure node affinity
* Configure pod anti-affinity
* Configure resource requests
* Configure resource limits
* Observe Kubernetes scheduling decisions

---

# Existing Cluster

```
                    +------------------------+
                    |  External ETCD Cluster |
                    |      ETCD-1            |
                    |      ETCD-2            |
                    |      ETCD-3            |
                    +-----------+------------+
                                |
      --------------------------------------------------------
                     Kubernetes Cluster
      --------------------------------------------------------

           +----------------+      +----------------+
           | Control Plane 1|      | Control Plane 2|
           +----------------+      +----------------+

                     |
      ---------------------------------------
      |                                     |

+------------------+              +------------------+
| Worker Node 1    |              | Worker Node 2    |
|                  |              |                  |
| Application Pool |              | Monitoring Pool  |
+------------------+              +------------------+
```

---

# Business Scenario

ABC Retail runs a production Kubernetes platform.

Different workloads require different nodes.

| Workload              | Requirement     |
| --------------------- | --------------- |
| Customer Applications | Worker Pool A   |
| Monitoring            | Worker Pool B   |
| Logging               | Worker Pool B   |
| Database              | Dedicated Nodes |
| AI Workloads          | GPU Nodes       |

The company wants to ensure

* Monitoring never mixes with applications
* Logging is isolated
* Critical applications receive guaranteed CPU and memory
* High Availability
* No noisy neighbors

Students will configure these policies.

---

# Lab Topology

Initially

```
Worker1

No labels
No taints


Worker2

No labels
No taints
```

Goal

```
Worker1

role=application
environment=production

Runs

NGINX
Web
API


-----------------------------------

Worker2

role=monitoring

Tainted

monitoring=true:NoSchedule

Runs

Prometheus
Grafana
Logging
```

---

# Lab Tasks

Students will perform the following

Task 1

Inspect cluster nodes

Task 2

Apply labels

Task 3

Verify labels

Task 4

Apply taints

Task 5

Verify taints

Task 6

Deploy application without toleration

Task 7

Observe scheduling failure

Task 8

Add toleration

Task 9

Verify deployment

Task 10

Configure node affinity

Task 11

Configure anti-affinity

Task 12

Configure resource requests

Task 13

Configure resource limits

Task 14

Verify pod placement

---

# Task 1

## View Cluster Nodes

```
kubectl get nodes
```

Expected Output

```
NAME
cp-01
cp-02
worker-01
worker-02
```

---

## Display Node Labels

```
kubectl get nodes --show-labels
```

---

# Task 2

## Label Worker Nodes

Worker 1

```
kubectl label node worker-01 role=application
```

```
kubectl label node worker-01 environment=production
```

Worker 2

```
kubectl label node worker-02 role=monitoring
```

```
kubectl label node worker-02 environment=production
```

Verify

```
kubectl get nodes --show-labels
```

---

# Task 3

## Configure Dedicated Monitoring Node

Apply taint

```
kubectl taint nodes worker-02 monitoring=true:NoSchedule
```

Verify

```
kubectl describe node worker-02
```

Expected

```
Taints:

monitoring=true:NoSchedule
```

---

# Task 4

Deploy Application Without Toleration

Create

```
nginx.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        role: monitoring
      containers:
      - name: nginx
        image: nginx
```

Apply

```
kubectl apply -f nginx.yaml
```

Observe

```
kubectl get pods
```

Pods remain Pending.

Explain why.

---

# Task 5

Describe Pending Pod

```
kubectl describe pod PODNAME
```

Students should identify

```
node(s) had taint

monitoring=true

that the pod didn't tolerate
```

---

# Task 6

Add Toleration

Update Deployment

```yaml
tolerations:

- key: monitoring
  operator: Equal
  value: "true"
  effect: NoSchedule
```

Apply

```
kubectl apply -f nginx.yaml
```

Observe

```
kubectl get pods -o wide
```

Pods now schedule to Worker 2.

---

# Task 7

Node Affinity

Deploy another application

```
frontend.yaml
```

Use

```yaml
affinity:

  nodeAffinity:

    requiredDuringSchedulingIgnoredDuringExecution:

      nodeSelectorTerms:

      - matchExpressions:

        - key: role
          operator: In
          values:

          - application
```

Expected

Pods only deploy to Worker 1.

---

# Task 8

Pod Anti-Affinity

Objective

Spread replicas across available nodes.

Example

```yaml
podAntiAffinity:

  preferredDuringSchedulingIgnoredDuringExecution:

  - weight: 100

    podAffinityTerm:

      topologyKey: kubernetes.io/hostname

      labelSelector:

        matchLabels:

          app: frontend
```

Observe

```
kubectl get pods -o wide
```

Students compare pod placement and discuss why, with only **two worker nodes**, complete spreading may be limited by existing node affinity and taints.

---

# Task 9

Configure Resource Requests

Deploy

```yaml
resources:

  requests:

    cpu: "250m"

    memory: "256Mi"
```

Observe

```
kubectl describe pod
```

Students identify

```
Requests
```

section.

---

# Task 10

Configure Resource Limits

```yaml
resources:

  limits:

    cpu: "500m"

    memory: "512Mi"
```

Verify

```
kubectl describe pod
```

Students observe

```
Limits
```

---

# Task 11

Observe Scheduling

Useful commands

```
kubectl get pods -o wide
```

```
kubectl describe node worker-01
```

```
kubectl describe node worker-02
```

```
kubectl top node
```

```
kubectl top pod
```

---

# Final Architecture

```
                    ETCD Cluster
           +-------------------------+
           | ETCD1 ETCD2 ETCD3       |
           +-----------+-------------+

                Kubernetes Cluster

        +-------------------------------+
        | CP1             CP2           |
        +-------------------------------+

                 Scheduler
                      |
      -----------------------------------------
      |                                       |

+-------------------------+      +----------------------------+
| Worker-01               |      | Worker-02                 |
| role=application         |      | role=monitoring           |
| environment=production   |      | monitoring=true           |
|                          |      | NoSchedule                |
|                          |      |                           |
| Frontend                 |      | Prometheus               |
| Backend                  |      | Grafana                  |
| API                      |      | Logging                  |
+-------------------------+      +----------------------------+
```

# Learning Outcomes

At the end of this lab, students will be able to:

* Design dedicated node pools using labels and taints.
* Control pod placement with `nodeSelector`, node affinity, and pod anti-affinity.
* Use tolerations to allow workloads onto tainted nodes.
* Configure CPU and memory requests and limits for predictable scheduling.
* Verify scheduling decisions using `kubectl describe`, `kubectl get pods -o wide`, and resource metrics.
* Understand how these mechanisms are combined in production EKS Anywhere clusters to isolate workloads, improve reliability, and optimize resource utilization.
