
# Lab Manual 1

# Enterprise Workstation Preparation for Amazon EKS Anywhere

## Lab Objective

In this lab, you will prepare the administration workstation used throughout the 16-day Enterprise Kubernetes Platform Engineering Bootcamp.

By the end of this lab, you will have a fully configured Ubuntu 24.04 management workstation capable of administering VMware vSphere and deploying Amazon EKS Anywhere clusters.

---

# Learning Objectives

After completing this lab, you will be able to:

* Verify Ubuntu 24.04 environment
* Update the operating system
* Install required operating system packages
* Install Docker Engine
* Install kubectl
* Install Helm
* Install ArgoCD CLI
* Install eksctl-anywhere
* Install govc
* Configure VMware credentials
* Validate connectivity with vCenter
* Verify software versions

---

# Estimated Duration

90 Minutes

---

# Lab Environment

| Component        | Details                             |
| ---------------- | ----------------------------------- |
| Operating System | Ubuntu Server 24.04 LTS             |
| RAM              | 8 GB+                               |
| CPU              | 4 vCPU                              |
| Internet         | Required                            |
| User             | student                             |
| Privileges       | sudo                                |
| VMware           | vCenter Server                      |
| Target           | EKS Anywhere Management Workstation |

---

# Architecture

```
                    +----------------------+
                    | Ubuntu Workstation   |
                    |----------------------|
                    | kubectl             |
                    | eksctl-anywhere     |
                    | Docker             |
                    | govc               |
                    | Helm              |
                    | ArgoCD CLI        |
                    +----------+---------+
                               |
                               |
                        HTTPS (443)
                               |
                 +-------------+--------------+
                 | vCenter Server             |
                 +-------------+--------------+
                               |
                 +-------------+--------------+
                 | ESXi Host 1               |
                 | ESXi Host 2               |
                 +---------------------------+
```

---

# Prerequisites

Ensure the following:

* Ubuntu 24.04 installed
* Internet connectivity available
* sudo access available
* vCenter credentials received from instructor

Example

```
vCenter IP

Username

Password

Datacenter Name

Cluster Name

Datastore

Network

VM Template
```

---

# Task 1 – Verify Ubuntu Installation

Display Ubuntu version

```bash
lsb_release -a
```

Expected Output

```
Ubuntu 24.04 LTS
```

---

Verify Kernel

```bash
uname -r
```

---

Check Disk Space

```bash
df -h
```

---

Check Memory

```bash
free -h
```

---

Check CPU

```bash
lscpu
```

---

# Task 2 – Update Ubuntu

Refresh package repository

```bash
sudo apt update
```

Upgrade installed packages

```bash
sudo apt upgrade -y
```

Reboot if required

```bash
sudo reboot
```

---

# Task 3 – Install Common Utilities

```bash
sudo apt install -y \
curl \
wget \
git \
jq \
unzip \
tar \
vim \
nano \
ca-certificates \
gnupg \
apt-transport-https \
software-properties-common
```

Verify

```bash
git --version

curl --version

jq --version
```

---

# Task 4 – Install Docker Engine

Remove older versions

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

Install prerequisites

```bash
sudo apt install ca-certificates curl -y
```

Create Docker key directory

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Download Docker GPG key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Configure Docker Repository

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list
```

Install Docker

```bash
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

Enable Docker

```bash
sudo systemctl enable docker

sudo systemctl start docker
```

Add current user

```bash
sudo usermod -aG docker $USER
```

Logout/Login

Verify

```bash
docker version

docker info
```

Run Test Container

```bash
docker run hello-world
```

---

# Task 5 – Install kubectl

Download

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Install

```bash
chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

Verify

```bash
kubectl version --client
```

---

# Task 6 – Install Helm

Download

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify

```bash
helm version
```

---

# Task 7 – Install ArgoCD CLI

Download latest

```bash
curl -sSL -o argocd \
https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
```

Make executable

```bash
chmod +x argocd

sudo mv argocd /usr/local/bin/
```

Verify

```bash
argocd version --client
```

---

# Task 8 – Install govc

Download latest

```bash
curl -L \
https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz \
-o govc.tar.gz
```

Extract

```bash
tar -xzf govc.tar.gz
```

Install

```bash
sudo mv govc /usr/local/bin/
```

Verify

```bash
govc version
```

---

# Task 9 – Install Amazon EKS Anywhere CLI

Download

```bash
RELEASE=$(curl https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | \
grep gitTag | head -1 | awk '{print $2}')
```

install eksctl
```bash
curl --silent --location \
"https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz

sudo mv eksctl /usr/local/bin/
```


Download binary

```bash
curl -L -o eksctl-anywhere.tar.gz https://github.com/aws/eks-anywhere/releases/download/v0.25.3/eksctl-anywhere-v0.25.3-linux-amd64.tar.gz
```

Check if the downloaded tar is fine
```bash
file eksctl-anywhere.tar.gz
```

Exected output
```
eksctl-anywhere.tar.gz: gzip compressed data, last modified: Wed Jul 22 10:09:27 2026, from Unix, original size modulo 2^32 99901440
```

Extract

```bash
tar -xzf eksctl-anywhere.tar.gz
```

Install

```bash
sudo mv eksctl-anywhere /usr/local/bin/
```

Verify

```bash
eksctl anywhere version
```

---

# Task 10 – Configure VMware Environment Variables

Example

```bash
export GOVC_URL='https://vcsa.lab.local'

export GOVC_USERNAME='administrator@vsphere.local'

export GOVC_PASSWORD='VMware123!'

export GOVC_INSECURE=1
```

Persist them

```bash
nano ~/.bashrc
```

Append

```bash
export GOVC_URL='https://vcsa.lab.local'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='VMware123!'
export GOVC_INSECURE=1
```

Reload

```bash
source ~/.bashrc
```

---

# Task 11 – Validate VMware Connectivity

Verify Login

```bash
govc about
```

Expected Output

```
Vendor

VMware

Version

Build

API Version
```

---

List Datacenters

```bash
govc datacenter.info
```

---

List Clusters

```bash
govc find / -type c
```

---

List Datastores

```bash
govc datastore.info
```

---

List Networks

```bash
govc find / -type n
```

---

List Resource Pools

```bash
govc find / -type p
```

---

List Templates

```bash
govc find / -type m
```

---

List Virtual Machines

```bash
govc ls /vm
```

---

# Task 12 – Verify All Installed Software

Run the following commands:

```bash
kubectl version --client

helm version

argocd version --client

docker version

govc version

eksctl anywhere version
```

Expected Result:

| Tool            | Status    |
| --------------- | --------- |
| Docker          | Installed |
| kubectl         | Installed |
| Helm            | Installed |
| ArgoCD CLI      | Installed |
| govc            | Installed |
| eksctl-anywhere | Installed |

---

# Troubleshooting Guide

| Issue                                          | Possible Cause                  | Resolution                                                      |
| ---------------------------------------------- | ------------------------------- | --------------------------------------------------------------- |
| `docker: permission denied`                    | User not in docker group        | `sudo usermod -aG docker $USER` and log out/in                  |
| `kubectl: command not found`                   | Binary not in PATH              | Verify `/usr/local/bin` is in `PATH`                            |
| `govc: login failed`                           | Incorrect vCenter credentials   | Recheck `GOVC_URL`, username, and password                      |
| `x509 certificate signed by unknown authority` | Self-signed vCenter certificate | Set `GOVC_INSECURE=1` for lab environments                      |
| `Unable to connect to vCenter`                 | DNS or network issue            | Verify `ping`, `nslookup`, and TCP port `443`                   |
| `eksctl anywhere version` fails                | Incomplete installation         | Re-download the correct binary and verify execution permissions |

