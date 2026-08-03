# Module 11 – Supply Chain Security

# Lab 1 – Image Vulnerability Scanning using Trivy

**Lab Duration:** 90–120 Minutes

**Difficulty:** Beginner to Intermediate

**Platform:** EKS Anywhere Lab Environment

**Student Prerequisites**

* Ubuntu 24.04 VM
* Docker installed
* kubectl installed
* Internet connectivity
* Git installed

---

# Lab Objective

In this lab students will learn how container image vulnerabilities are identified before deployment into Kubernetes.

At the end of this lab students will be able to:

* Install Trivy
* Scan container images
* Understand CVEs
* Interpret CVSS scores
* Understand Fixed Versions
* Identify vulnerable base images
* Generate JSON reports
* Generate HTML reports
* Scan Kubernetes YAML files
* Scan local filesystem
* Understand DevSecOps image scanning workflow

---

# Lab Architecture

```
              Docker Hub
                   │
         Pull Container Images
                   │
                   ▼
              Docker Images
                   │
          Trivy Vulnerability Scan
                   │
     ┌─────────────┼──────────────┐
     │             │              │
     ▼             ▼              ▼
 Terminal      JSON Report    HTML Report
                   │
                   ▼
        Developer fixes issues
                   │
                   ▼
      Deploy to Kubernetes Cluster
```

---

# What is Trivy?

Trivy is an open-source vulnerability scanner developed by Aqua Security.

It scans

* Container Images
* Filesystems
* Git Repositories
* Kubernetes Manifests
* Dockerfiles
* Helm Charts
* SBOM
* Secrets
* Misconfigurations

---

# Lab 1 – Install Trivy

## Step 1 Verify Docker

```bash
docker version
```

Expected

```
Client:
 Version: 28.x.x
```

---

## Step 2 Update Ubuntu

```bash
sudo apt update
```

---

## Step 3 Install Required Packages

```bash
sudo apt install wget apt-transport-https gnupg lsb-release -y
```

---

## Step 4 Download Trivy Repository Key

```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
```

---

## Step 5 Add Repository

```bash
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
sudo tee /etc/apt/sources.list.d/trivy.list
```

---

## Step 6 Install Trivy

```bash
sudo apt update

sudo apt install trivy -y
```

---

## Step 7 Verify Installation

```bash
trivy --version
```

Example

```
Version: 0.66.x
```

---

# Understanding Trivy Database

The first scan downloads a vulnerability database.

Run

```bash
trivy image nginx
```

First execution downloads

```
Downloading vulnerability DB...
```

Database Size

Around 60–100 MB (may vary).

---

# Lab 2 – Pull Images

Pull nginx

```bash
docker pull nginx
```

Pull Ubuntu

```bash
docker pull ubuntu:22.04
```

Verify

```bash
docker images
```

Example

```
nginx

ubuntu
```

---

# Lab 3 – Scan nginx Image

Run

```bash
trivy image nginx
```

Wait until scan completes.

---

# Sample Output

```
nginx

Total: 43

CRITICAL: 2

HIGH: 15

MEDIUM: 18

LOW: 8
```

Numbers will vary.

---

# Understanding the Report

Example

```
openssl

Installed Version

3.0.2

Fixed Version

3.0.16

Severity

CRITICAL

CVE

CVE-2025-12345
```

Meaning

Installed package contains a vulnerability.

---

# Important Columns

## Package

Example

```
openssl
```

Library having vulnerability.

---

## Installed Version

```
3.0.2
```

Current package.

---

## Fixed Version

```
3.0.16
```

Upgrade to remove vulnerability.

---

## Severity

```
LOW

MEDIUM

HIGH

CRITICAL
```

---

## CVE

Example

```
CVE-2025-12345
```

Unique vulnerability identifier.

---

# What is CVE?

CVE

Common Vulnerabilities and Exposures

Example

```
CVE-2024-3094
```

Every known security issue receives a unique CVE ID.

---

# What is CVSS?

CVSS

Common Vulnerability Scoring System

Score Range

```
0-3.9 Low

4-6.9 Medium

7-8.9 High

9-10 Critical
```

---

# Example

```
Severity

Critical

CVSS

9.8
```

This vulnerability should be fixed immediately.

---

# Why Fixed Version Matters

Suppose

```
Installed

OpenSSL 3.0.2
```

Available

```
3.0.16
```

After rebuilding image with latest package

```
Critical Vulnerability disappears
```

---

# Lab 4 – Scan Ubuntu Image

Run

```bash
trivy image ubuntu:22.04
```

Observe

* Total vulnerabilities
* High
* Critical
* Packages

---

# Compare Images

| Image  | Total Vulnerabilities | Critical | High   |
| ------ | --------------------- | -------- | ------ |
| nginx  | ______                | ______   | ______ |
| ubuntu | ______                | ______   | ______ |

Students fill values.

---

# Discussion

Questions

Which image is safer?

Which has more vulnerabilities?

Why?

Expected Answer

Depends upon

* Base OS
* Installed packages
* Image size
* Package versions

---

# Lab 5 – Scan Specific Severity

Only Critical

```bash
trivy image --severity CRITICAL nginx
```

Critical + High

```bash
trivy image --severity HIGH,CRITICAL nginx
```

---

# Lab 6 – Ignore Unfixed Vulnerabilities

Many vulnerabilities have no available fix yet.

Run

```bash
trivy image --ignore-unfixed nginx
```

Observe

Critical count decreases.

---

# Lab 7 – Generate JSON Report

Create report

```bash
trivy image \
--format json \
-o nginx-report.json \
nginx
```

Verify

```bash
ls
```

View

```bash
cat nginx-report.json
```

Pretty print (optional, if `jq` is installed)

```bash
jq . nginx-report.json
```

---

# Understanding JSON Report

Notice

```
Results

Packages

Severity

Description

References

CVE

CVSS

FixedVersion
```

JSON reports are commonly uploaded to CI/CD pipelines or artifact repositories for auditing.

---

# Lab 8 – Generate HTML Report

## Step 1 Download Trivy HTML Template

```bash
wget https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl
```

---

## Step 2 Generate HTML Report

```bash
trivy image \
--format template \
--template "@html.tpl" \
-o nginx-report.html \
nginx
```

---

## Step 3 View Report

Install a simple browser if required:

```bash
sudo apt install firefox -y
```

Open report

```bash
firefox nginx-report.html
```

Or

```bash
xdg-open nginx-report.html
```

---

# Observe

Beautiful dashboard

Contains

* Severity graph
* Packages
* CVEs
* Fixed versions

---

# Lab 9 – Scan Kubernetes YAML

Create directory

```bash
mkdir kube-scan

cd kube-scan
```

Create deployment

```bash
cat <<EOF > nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
```

---

Run

```bash
trivy config nginx.yaml
```

---

Observe

Possible findings

* No resource limits
* No security context
* Latest image tag
* Missing readOnlyRootFilesystem
* Privileged container (if configured)
* Missing capabilities drop

---

# Why Configuration Scanning?

Image may be secure.

Deployment may still be insecure.

Examples

Running as root

Host networking

Host PID

Host IPC

Missing resource limits

No read-only filesystem

Configuration scanning helps identify these issues before deployment.

---

# Lab 10 – Scan Local Filesystem

Return to home

```bash
cd ~
```

Run

```bash
trivy fs .
```

---

Trivy scans

* Dependencies
* Secrets
* Vulnerabilities
* Misconfigurations

---

Scan a specific project

```bash
trivy fs ~/myproject
```

---

# Lab 11 – Scan Only Secrets

```bash
trivy fs \
--scanners secret \
.
```

Finds

AWS Keys

GitHub Tokens

Passwords

API Keys

Private Keys

---

# Lab 12 – Scan Dockerfile

Example Dockerfile

```Dockerfile
FROM ubuntu:22.04

RUN apt update

RUN apt install -y nginx

CMD ["nginx","-g","daemon off;"]
```

Scan

```bash
trivy config Dockerfile
```

Observe recommendations regarding image choice and configuration.

---

# Understanding Base Image Risk

Compare

```
ubuntu
```

vs

```
alpine
```

Typically

```
Ubuntu

Large image

More packages

More vulnerabilities
```

```
Alpine

Smaller

Minimal packages

Fewer vulnerabilities
```

> Note: Fewer vulnerabilities does not automatically mean "more secure" for every workload. Choose base images based on application compatibility, support, update cadence, and security requirements.

---

# Best Practices

Always

* Scan every image
* Scan before deployment
* Use minimal base images
* Fix Critical vulnerabilities first
* Upgrade packages regularly
* Avoid latest tag in production
* Generate reports for auditing
* Integrate Trivy into CI/CD pipelines

---

# Cleanup

Remove reports

```bash
rm -f nginx-report.json nginx-report.html html.tpl
```

Remove images (optional)

```bash
docker rmi nginx ubuntu:22.04
```

---

# Expected Learning Outcomes

After completing this lab, students should be able to:

* Install and configure Trivy.
* Explain the concepts of **CVE**, **CVSS**, **severity levels**, and **fixed versions**.
* Scan container images and interpret vulnerability reports.
* Compare the security posture of different base images.
* Generate machine-readable (JSON) and human-readable (HTML) scan reports.
* Scan Kubernetes manifests for configuration issues.
* Scan local filesystems for vulnerabilities, misconfigurations, and secrets.
* Understand how image scanning fits into a DevSecOps supply chain security workflow.

