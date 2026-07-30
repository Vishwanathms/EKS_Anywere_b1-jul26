# Lab Manual: Installing MetalLB on an EKS Anywhere Cluster (vSphere)

## Module: Networking Services for Bare Metal Kubernetes

### Lab Duration: 45–60 Minutes

### Difficulty: Intermediate

---

# Lab Objective

At the end of this lab, students will be able to:

* Understand why MetalLB is required
* Understand Layer2 vs BGP mode
* Install MetalLB
* Configure IP Address Pools
* Configure Layer2 Advertisement
* Deploy a LoadBalancer service
* Verify external IP assignment
* Troubleshoot common issues

---

# Lab Architecture

```
                    Users
                      |
             -----------------
             |               |
      192.168.100.240
      LoadBalancer IP
             |
      +----------------+
      |    MetalLB     |
      | Speaker + Ctrl |
      +----------------+
              |
   -----------------------------
   |            |             |
 Control     Worker-1      Worker-2
              |
      Kubernetes Cluster
```

---

# Prerequisites

Students should already have

* Running EKS Anywhere Cluster
* kubectl installed
* Cluster admin access
* Internet connectivity
* Metrics Server installed (optional)
* Ingress Controller not required

Verify cluster

```bash
kubectl get nodes
```

Example

```
NAME                 STATUS
mgmt-control-01      Ready
worker-01            Ready
worker-02            Ready
```

---

# Step 1 Verify Cluster Health

Check Nodes

```bash
kubectl get nodes -o wide
```

Check System Pods

```bash
kubectl get pods -A
```

Everything should be Running.

---

# Step 2 Understand MetalLB

In cloud Kubernetes

```
AWS
Azure
GCP
```

A Service of type LoadBalancer automatically receives an external IP.

Example

```
Service

Type:
LoadBalancer

↓

AWS ELB

↓

Public IP
```

---

In EKS Anywhere

There is **NO cloud load balancer.**

Therefore

```
Service
↓

Waiting...

EXTERNAL-IP = Pending
```

MetalLB solves this problem.

---

# Step 3 Select IP Range

MetalLB needs a pool of IPs.

Choose unused IPs from your network.

Example

Network

```
192.168.1.0/24
```

Gateway

```
192.168.1.1
```

DHCP

```
192.168.1.XX
to
192.168.1.XX
```

Reserve

```
192.168.1.YY
to
192.168.1.YY
```

for MetalLB.

Example Pool

```
192.168.1.cluser-IP+1-192.168.1.cluser-IP+3
```

Never use

* Node IPs
* Gateway
* DHCP Range
* DNS Server IP

---

# Step 4 Install MetalLB Namespace

```bash
kubectl create namespace metallb-system
```

Verify

```bash
kubectl get ns
```

---

# Step 5 Install MetalLB

Apply the official manifest.

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
```

Expected

```
namespace/metallb-system created

deployment/controller created

daemonset/speaker created
```

---

# Step 6 Verify Installation

Check Pods

```bash
kubectl get pods -n metallb-system
```

Example

```
controller

Running

speaker-xm2df

Running

speaker-r43de

Running
```

Verify

```bash
kubectl get all -n metallb-system
```

---

# Step 7 Verify Speaker DaemonSet

```bash
kubectl get daemonset -n metallb-system
```

Example

```
NAME

speaker

Desired

3

Ready

3
```

One speaker should run on every node.

---

# Step 8 Create IPAddressPool

Create file

```bash
vi ip-pool.yaml
```

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production-pool
  namespace: metallb-system

spec:
  addresses:
  - 192.168.100.240-192.168.100.250
```

Apply

```bash
kubectl apply -f ip-pool.yaml
```

Verify

```bash
kubectl get ipaddresspool -n metallb-system
```

Describe

```bash
kubectl describe ipaddresspool production-pool \
-n metallb-system
```

---

# Step 9 Create Layer2Advertisement

Create file

```bash
vi l2.yaml
```

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement

metadata:
  name: layer2
  namespace: metallb-system

spec:
  ipAddressPools:
  - production-pool
```

Apply

```bash
kubectl apply -f l2.yaml
```

Verify

```bash
kubectl get layer2advertisement -n metallb-system
```

---

# Step 10 Verify CRDs

```bash
kubectl get crd | grep metallb
```

Expected

```
ipaddresspools.metallb.io

l2advertisements.metallb.io

bgppeers.metallb.io

bfdprofiles.metallb.io
```

---

# Step 11 Deploy Test Application

```bash
kubectl create deployment nginx \
--image=nginx
```

Scale

```bash
kubectl scale deployment nginx \
--replicas=2
```

Verify

```bash
kubectl get pods
```

---

# Step 12 Expose Service

```bash
kubectl expose deployment nginx \
--port=80 \
--target-port=80 \
--type=LoadBalancer
```

Verify

```bash
kubectl get svc
```

Initially

```
Pending
```

After a few seconds

```
NAME

nginx

TYPE

LoadBalancer

EXTERNAL-IP

192.168.100.240
```

---

# Step 13 Verify Assigned IP

Describe Service

```bash
kubectl describe svc nginx
```

Look for

```
LoadBalancer Ingress

192.168.100.240
```

---

# Step 14 Test Connectivity

From another machine

```bash
curl http://192.168.100.240
```

or

Open Browser

```
http://192.168.100.240
```

Expected

```
Welcome to nginx!
```

---

# Step 15 Observe Speaker Logs

```bash
kubectl logs \
-n metallb-system \
daemonset/speaker
```

Observe

```
announcing

assigned

ARP advertisement
```

---

# Step 16 Observe Controller Logs

```bash
kubectl logs \
deployment/controller \
-n metallb-system
```

Observe

```
Assigning IP

Updating Service
```

---

# Step 17 Test Multiple Services

Deploy

```bash
kubectl create deployment apache \
--image=httpd
```

Expose

```bash
kubectl expose deployment apache \
--port=80 \
--type=LoadBalancer
```

Verify

```bash
kubectl get svc
```

Example

```
nginx

192.168.100.240

apache

192.168.100.241
```

---

# Step 18 Delete Service

```bash
kubectl delete svc nginx
```

Verify

```bash
kubectl get svc
```

Observe

```
IP released
```

Deploy again.

MetalLB allocates another available IP.

---

# Step 19 Check Events

```bash
kubectl get events -A
```

Observe MetalLB events.

---

# Step 20 Troubleshooting

## External IP Pending

Check

```bash
kubectl get ipaddresspool -A
```

---

Check

```bash
kubectl get l2advertisement -A
```

---

Check

```bash
kubectl get pods -n metallb-system
```

---

Check logs

```bash
kubectl logs deployment/controller \
-n metallb-system
```

---

## Speaker Not Running

Check

```bash
kubectl get daemonset \
-n metallb-system
```

---

Describe

```bash
kubectl describe daemonset speaker \
-n metallb-system
```

---

## Wrong IP Pool

Verify

```bash
kubectl describe ipaddresspool production-pool \
-n metallb-system
```

---

## IP Conflict

Use

```bash
arp -a
```

or

```bash
ping
```

Ensure IPs are unused before adding them to the pool.

---

# Step 21 Clean Up

Delete test application

```bash
kubectl delete deployment nginx
kubectl delete svc nginx
```

Delete Apache

```bash
kubectl delete deployment apache
kubectl delete svc apache
```

Delete Layer2Advertisement

```bash
kubectl delete -f l2.yaml
```

Delete Pool

```bash
kubectl delete -f ip-pool.yaml
```

---

# Validation Checklist

| Task                         | Status |
| ---------------------------- | ------ |
| Cluster Healthy              | ☐      |
| MetalLB Installed            | ☐      |
| Controller Running           | ☐      |
| Speakers Running             | ☐      |
| IPAddressPool Created        | ☐      |
| Layer2Advertisement Created  | ☐      |
| NGINX Deployment Created     | ☐      |
| LoadBalancer Service Created | ☐      |
| External IP Assigned         | ☐      |
| Browser Access Successful    | ☐      |
| Logs Verified                | ☐      |
| Cleanup Completed            | ☐      |

---

# Best Practices for EKS Anywhere

* Reserve a dedicated IP range exclusively for MetalLB; never overlap with DHCP or static node addresses.
* Use Layer 2 mode for most VMware/vSphere training and lab environments. BGP mode is more suitable for enterprise networks with router integration.
* Keep the IPAddressPool and Layer2Advertisement resources in version control (GitOps) alongside the cluster configuration.
* Monitor MetalLB controller and speaker logs regularly when troubleshooting networking issues.
* If you deploy an ingress controller (such as NGINX Ingress), expose the ingress service using `type: LoadBalancer` so MetalLB can assign an external IP automatically.
* In production, document and reserve the MetalLB IP pool in your network management process to avoid conflicts.

This lab is well-suited for your EKS Anywhere classroom environment because students can each use a dedicated IP range from the shared training network while following the same repeatable procedure.
