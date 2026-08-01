Since you already have a **3-node EKS Anywhere cluster** running, you do **not** need the air-gapped installer (`radm`) that provisions Kubernetes itself. You should use the **Helm-based installation** for an existing Kubernetes cluster. ([Rafay Docs][1])

The overall workflow is:

```text
Existing 3-Node EKS Anywhere Cluster
           │
           │
    Verify Prerequisites
           │
           ▼
 Configure DNS & TLS
           │
           ▼
 Obtain Rafay Installation Package
           │
           ▼
 Edit values.yaml
           │
           ▼
 Install Dependencies
           │
           ▼
 Install Rafay Controller
           │
           ▼
 Install Istio Rules
           │
           ▼
 Verify Pods
           │
           ▼
 Access Rafay UI
           │
           ▼
 Register Clusters
```

---

# Step 1 – Verify the Cluster

Your cluster should have:

```bash
kubectl get nodes
kubectl get storageclass
kubectl get ingressclass
kubectl get ns
helm version
kubectl version
```

You should confirm:

* 3 healthy nodes
* Default StorageClass
* Helm 3 installed
* `kubectl` access
* Sufficient CPU, memory, and storage for the controller. ([Rafay Docs][1])

---

# Step 2 – Configure DNS

For a lab, you can use a DNS zone such as:

```text
console.rafay.lab
ops-console.rafay.lab
login.rafay.lab
```

Create DNS records pointing to the ingress or load balancer that fronts the controller. ([Rafay Docs][1])

---

# Step 3 – TLS Certificate

Create a wildcard certificate, for example:

```text
*.rafay.lab
```

or use a self-signed certificate in a lab environment.

---

# Step 4 – Obtain the Rafay Installation Package

The package is **not publicly downloadable**. It is provided by Rafay Support or through the customer portal and contains the Helm charts and supporting assets. ([Rafay Docs][1])

Typical contents include:

```text
rafay-dep-<version>.tgz
rafaycore-<version>.tgz
istio-rules-<version>.tgz
values.yaml
README
```

---

# Step 5 – Extract the Package

```bash
tar -xvf rafay-helm-controller-<version>.tar.gz

cd rafay-helm-controller
```

---

# Step 6 – Edit `values.yaml`

Configure items such as:

```yaml
domain: rafay.lab

tls:
  enabled: true

ingress:
  enabled: true

storage:
  storageClass: openebs-hostpath

controller:
  ha: true
```

You will also configure items like:

* Domain
* Certificate
* StorageClass
* High Availability
* Registry (if applicable)
* Ingress

---

# Step 7 – Install Dependencies

```bash
helm install rafay-dep \
    -f values.yaml \
    ./rafay-dep-<version>.tgz
```

Wait until all dependency pods are running before proceeding. ([Rafay Docs][1])

---

# Step 8 – Verify Dependencies

```bash
kubectl get pods -A
```

You should see components such as:

* PostgreSQL
* Istio
* cert-manager
* Kafka
* Elasticsearch/OpenSearch
* Metrics Server
* Supporting operators

depending on your deployment configuration. ([Rafay Docs][2])

---

# Step 9 – Install the Rafay Controller

```bash
helm install rafay-core \
    -n rafay-core \
    -f values.yaml \
    ./rafaycore-<version>.tgz
```

([Rafay Docs][1])

---

# Step 10 – Install Istio Rules

```bash
helm install istio-rules \
    -n istio-system \
    -f values.yaml \
    ./istio-rules-<version>.tgz
```

([Rafay Docs][1])

---

# Step 11 – Verify the Installation

```bash
kubectl get pods -n rafay-core
```

All controller pods should eventually reach the **Running** state.

---

# Step 12 – Access the UI

Open:

```text
https://console.rafay.lab
```

or your configured controller hostname.

Create the first organization (or use the Operations Console if your deployment workflow requires it) and log in with the configured administrator credentials. ([Rafay Docs][2])

---

# Step 13 – Register EKS Anywhere Clusters

From the Rafay UI:

1. Create an Organization.
2. Create a Project.
3. Add an existing Kubernetes cluster.
4. Download the Rafay Agent manifest.
5. Apply it to the target EKS Anywhere cluster.
6. Verify the cluster appears in the controller.

---

## What You Need Before Starting

* Existing 3-node EKS Anywhere cluster (already available)
* `kubectl` configured
* Helm 3 installed
* A default StorageClass
* Ingress or LoadBalancer access
* DNS records
* TLS certificate
* Rafay license
* Rafay Helm installation package from Rafay
* Internet access (or the appropriate image registry if using a restricted environment) ([Rafay Docs][1])

### If you're creating a training environment

I can also prepare a **50+ page step-by-step lab manual** that starts from a fresh 3-node EKS Anywhere cluster and covers:

* Preparing the EKS Anywhere cluster for Rafay
* Configuring MetalLB and NGINX Ingress (if needed)
* Setting up DNS and TLS
* Installing the Rafay Self-Hosted Controller
* Creating Organizations and Projects
* Registering each student's EKS Anywhere cluster
* Creating Blueprints and deploying workloads through Rafay

This format is well suited for instructor-led training.

[1]: https://docs.rafay.co/selfhosted/installation_helm/?utm_source=chatgpt.com "Controller Installation using Helm"
[2]: https://docs.rafay.co/selfhosted/airgapped/install/?utm_source=chatgpt.com "Air-Gapped Controller Installation"
