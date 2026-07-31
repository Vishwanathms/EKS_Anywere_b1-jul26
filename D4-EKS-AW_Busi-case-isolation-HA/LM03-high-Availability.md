# Lab Part 2 – High Availability Validation

## Scenario

ABC Retail's Service Level Agreement (SLA) requires applications to remain available during a worker node failure.

The Kubernetes administrator must verify that workloads are distributed appropriately and understand the behavior during node outages.

---

## Student Tasks

### Task 1

Deploy a production application with multiple replicas.

Requirement:

* Three replicas
* Rolling Update strategy

---

### Task 2

Configure Pod Anti-Affinity

Students configure scheduling preferences to spread replicas across available worker nodes where possible.

Objective:

Avoid placing all replicas on the same worker whenever the cluster topology allows.

---

### Task 3

Verify Pod Distribution

Students examine:

```
kubectl get pods -o wide
```

Questions:

* Which node hosts each replica?
* Why were replicas placed there?
* Which scheduling rules influenced the decision?

---

### Task 4

Simulate Worker Node Failure

The instructor powers off or shuts down **Worker-01** from vSphere.

Students monitor:

```
kubectl get nodes
```

```
kubectl get pods -w
```

Observe:

* Node transitions to `NotReady`.
* Pods on the failed node enter `Unknown` or `Terminating`.
* Kubernetes recreates pods on the remaining schedulable worker only if scheduling constraints (labels, taints, tolerations, affinity) permit it.

---

### Task 5

Validate Application Availability

Students verify:

* Deployment status.
* Replica count.
* Service accessibility.
* Pod health.

Discuss:

* Which replicas recovered?
* Which scheduling policies limited recovery?
* How would adding more application worker nodes improve availability?

---

### Task 6

Recover the Failed Worker

Power on Worker-01.

Observe:

* Node returns to `Ready`.
* Existing pods are **not automatically rebalanced**; Kubernetes leaves running pods in place unless a new scheduling event occurs.

This reinforces an important production behavior.

---

## Final Validation Checklist

Students should confirm:

✓ Workloads are isolated using labels, taints, and tolerations.

✓ Business applications do not run on monitoring nodes.

✓ Monitoring workloads are isolated.

✓ Production workloads have defined CPU and memory requests and limits.

✓ Replica placement follows affinity and anti-affinity rules where possible.

✓ The cluster detects worker node failure.

✓ Applications continue operating within the constraints of the remaining worker capacity.

✓ Students understand the relationship between scheduling policies and high availability in a fixed-size EKS Anywhere cluster.

---