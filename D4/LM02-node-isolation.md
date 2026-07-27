
# Business Scenario

Your organization, **ABC Retail Pvt. Ltd.**, has deployed a production EKS Anywhere cluster on VMware vSphere.

The infrastructure team has completed the Kubernetes installation, but the platform engineering team has identified several operational issues.

Currently:

* Every application can run on any worker node.
* Monitoring workloads compete with business applications.
* Critical business applications are not protected from resource starvation.
* Multiple replicas of the same application may be scheduled on the same worker node, creating a single point of failure.
* The operations team wants to verify that the cluster can continue serving applications even when one worker node becomes unavailable.

Your task as a Kubernetes Platform Engineer is to redesign the workload placement strategy without adding any new nodes.

---

# Existing Infrastructure

```
                    External ETCD Cluster
              +----------------------------+
              | ETCD-1  ETCD-2  ETCD-3     |
              +-------------+--------------+
                            |
        ------------------------------------------------
                    EKS Anywhere Cluster
        ------------------------------------------------

          +----------------+     +----------------+
          | Control Plane 1|     | Control Plane 2|
          +----------------+     +----------------+

                     |
        -----------------------------------------
        |                                       |
+--------------------+               +--------------------+
| Worker Node 01     |               | Worker Node 02     |
|                    |               |                    |
| All Workloads      |               | All Workloads      |
+--------------------+               +--------------------+
```

---

# Lab Objectives

At the end of this lab, students should be able to:

* Design workload isolation using Kubernetes scheduling features.
* Prevent applications from running on inappropriate nodes.
* Reserve dedicated infrastructure for monitoring workloads.
* Distribute application replicas across multiple nodes.
* Configure guaranteed resources for production applications.
* Validate application availability during worker node failure.

---

# Production Requirements

The platform team has defined the following deployment policy.

| Workload              | Requirement                                         |
| --------------------- | --------------------------------------------------- |
| Business Applications | Must run only on Application Nodes                  |
| Monitoring Stack      | Must run only on Monitoring Node                    |
| Critical APIs         | Must always have replicas on different worker nodes |
| Production Pods       | Must have guaranteed CPU and Memory                 |
| Node Failure          | Applications must remain available                  |

---

# Lab Architecture After Completion

```
                    External ETCD Cluster

           ETCD1      ETCD2      ETCD3

                    Kubernetes Cluster

          +-------------------------------+
          | CP-01             CP-02       |
          +-------------------------------+

                     Scheduler

          -------------------------------
          |                             |

+-------------------------+     +--------------------------+
| Worker-01               |     | Worker-02               |
| role=application        |     | role=monitoring         |
|                         |     | monitoring=true         |
|                         |     | NoSchedule              |
|                         |     |                         |
| Web Application         |     | Prometheus             |
| API                     |     | Grafana                |
| Backend                 |     | Logging                |
+-------------------------+     +--------------------------+
```

---

# Lab Part 1 – Node Isolation

## Scenario

The operations team wants complete workload isolation.

Business applications must never consume resources reserved for infrastructure services.

Monitoring workloads must never run with customer-facing applications.

Students must redesign the cluster scheduling policy.

---

## Student Tasks

### Task 1

Inspect the existing cluster.

Verify:

* Nodes
* Labels
* Taints
* Current pod placement

---

### Task 2

Create logical node roles.

Assign:

Worker-01

```
role=application
environment=production
```

Worker-02

```
role=monitoring
environment=production
```

---

### Task 3

Protect the Monitoring Node

Apply a taint to Worker-02.

Expected outcome:

Normal applications should no longer schedule on this node.

---

### Task 4

Deploy Business Application

Deploy a three-replica NGINX application.

Configure scheduling so that:

* It runs only on the Application Node.
* It cannot be scheduled on the Monitoring Node.

Students should use:

* Labels
* Node Selector or Node Affinity

---

### Task 5

Deploy Monitoring Application

Deploy a sample monitoring workload.

Configure:

* Toleration
* Node Affinity

Expected result:

Monitoring application runs only on Worker-02.

---

### Task 6

Configure Resource Requests

Assign production resource requests.

Example:

* CPU Requests
* Memory Requests

Students verify:

```
kubectl describe pod
```

---

### Task 7

Configure Resource Limits

Protect the cluster against resource overconsumption.

Verify limits are applied correctly.

---

## Validation Checklist

Students should confirm:

✓ Business applications run only on Worker-01.

✓ Monitoring applications run only on Worker-02.

✓ Monitoring node rejects normal applications.

✓ Resource requests are visible.

✓ Resource limits are enforced.

---

