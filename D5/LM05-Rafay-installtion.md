Excellent. Now that **OpenEBS is working**, we can move to the **Rafay Self-Hosted installation**.

However, there is one important point before we proceed.

## The Rafay Self-Hosted installation package is not publicly available

Unlike OpenEBS or ArgoCD, Rafay is a commercial product. The actual installation artifacts are provided by Rafay and include:

```
rafay-dep-<version>.tgz
rafay-core-<version>.tgz
istio-rules-<version>.tgz
values.yaml
license.yaml (or license key)
```

Without these Helm charts, I cannot provide the exact installation commands because the chart names, values, and configuration options vary by Rafay release.

---

# Here's what I can provide

I can create a **complete instructor lab manual** with all the infrastructure preparation and validation steps, and then fill in the Rafay-specific installation commands based on your installation package.

## Lab 02 – Preparing the Cluster for Rafay

### Objective

Prepare the EKS Anywhere cluster for Rafay Self-Hosted installation.

---

## Step 1 – Verify Cluster Health

```bash
kubectl get nodes -o wide

kubectl get pods -A

kubectl top nodes
```

Expected:

* All nodes `Ready`
* CoreDNS Running
* CNI Running
* Metrics Server Running

---

## Step 2 – Verify Storage

```bash
kubectl get storageclass

kubectl get pods -n openebs
```

Expected:

```
openebs-hostpath (default)
```

---

## Step 3 – Verify Ingress Controller

```bash
kubectl get pods -n ingress-nginx

kubectl get svc -n ingress-nginx
```

Expected:

```
ingress-nginx-controller
```

---

## Step 4 – Verify MetalLB

```bash
kubectl get pods -n metallb-system

kubectl get ipaddresspool -A

kubectl get l2advertisement -A
```

Expected:

* Speaker Running
* Controller Running
* IP pool configured

---

## Step 5 – Verify DNS

From your laptop:

```bash
nslookup rafay.lab.local
```

or

```bash
dig rafay.lab.local
```

The name should resolve to the MetalLB IP that will front the ingress.

---

## Step 6 – Create TLS Certificate

For a lab, you can use a self-signed wildcard certificate or one issued by your internal CA.

Create the Kubernetes secret:

```bash
kubectl create secret tls rafay-tls \
  --cert=rafay.crt \
  --key=rafay.key \
  -n ingress-nginx
```

---

## Step 7 – Verify Helm

```bash
helm version

helm repo list
```

---

## Step 8 – Create Namespaces

If the installation guide requires them (some charts create them automatically):

```bash
kubectl create namespace rafay-system
kubectl create namespace rafay-core
```

---

## Step 9 – Prepare the Installation Package

Extract the package:

```bash
tar -xvf rafay-selfhosted-<version>.tar.gz
```

Typical layout:

```
rafay-install/
├── charts/
│   ├── rafay-dep-<version>.tgz
│   ├── rafay-core-<version>.tgz
│   └── istio-rules-<version>.tgz
├── values.yaml
├── install.sh
└── README.md
```

---

## Step 10 – Review `values.yaml`

You'll configure items such as:

* Controller hostname
* TLS secret
* StorageClass (`openebs-hostpath`)
* Ingress
* Registry
* License
* SMTP
* Database options

---

# What I Need From You

To build the **exact Rafay installation lab**, I need the installation package or at least the chart names and default values.

Please upload one of the following:

1. **The Rafay installation tarball** (preferred), for example:

   * `rafay-selfhosted-<version>.tar.gz`
   * `rafay-install-<version>.tar.gz`

2. Or, if you cannot share the full package, upload:

   * `values.yaml`
   * `README.md`
   * `install.sh`
   * The output of:

     ```bash
     ls -R
     ```

     from the extracted installation directory.

---

## What You'll Get

Once I have the package details, I'll create a **production-quality, 100+ page lab manual** that includes:

* Detailed explanations of every component.
* Exact Helm commands for your Rafay version.
* Expected outputs after each step.
* Verification and health checks.
* Common troubleshooting scenarios.
* Architecture diagrams.
* Student exercises.
* Instructor notes and checkpoints.

This will be tailored specifically to **your Rafay release**, avoiding generic commands that may not match the charts you received from Rafay.
