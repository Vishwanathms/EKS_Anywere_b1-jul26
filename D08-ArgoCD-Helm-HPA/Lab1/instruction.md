Lab 1
GitOps using Plain Kubernetes YAML

Repository

gitops-nginx/

├── deployment.yaml
├── service.yaml
├── ingress.yaml

Deployment

env:

COMPANY

APPLICATION

VERSION

COLOR

BUILD_DATE

Students

git push

↓

ArgoCD Sync

↓

Pod recreated

↓

Browser updated

Learning

Git is source of truth
ArgoCD reconciliation
Automatic deployment

===================
Initial Deployment
git clone https://github.com/<studentname>/gitops-nginx.git

cd gitops-nginx

git add .

git commit -m "Initial GitOps deployment"

git push

ArgoCD automatically detects:

Git Repository

↓

New Commit

↓

ArgoCD detects change

↓

Manifest comparison

↓

Deployment updated

↓

ReplicaSet created

↓

Pod recreated

↓

Application updated
Exercise 1

Change

- name: VERSION
  value: "v1.0.0"

to

- name: VERSION
  value: "v1.1.0"

Commit

git add .

git commit -m "Upgrade to version 1.1.0"

git push

Observe

ArgoCD

↓

OutOfSync

↓

Sync

↓

Deployment Updated

↓

New ReplicaSet

↓

New Pod

↓

Browser shows

Version : v1.1.0
Exercise 2

Change

- name: ENVIRONMENT
  value: "Development"

to

- name: ENVIRONMENT
  value: "Testing"

Commit

git commit -am "Move application to Testing"

git push

Expected browser output

Environment : Testing
Exercise 3

Change

- name: COLOR_THEME
  value: "Blue"

to

- name: COLOR_THEME
  value: "Green"

Commit

git commit -am "Change theme to Green"

git push

Browser

Color Theme : Green
Exercise 4

Change

- name: COMPANY
  value: "Vishwacloudlab"

to

- name: COMPANY
  value: "AWS Academy"

Commit

git commit -am "Update company"

git push
Exercise 5

Update the build date

- name: BUILD_DATE
  value: "31-Jul-2026"

Commit

git commit -am "New build"

git push
Lab Outcome

By the end of this lab, students will understand:

Git is the single source of truth for application configuration.
ArgoCD continuously monitors the Git repository for changes.
Updating only Kubernetes YAML (no image rebuild) triggers a deployment.
The Deployment controller performs a rolling update, creating a new ReplicaSet and replacing Pods.
The application updates automatically after synchronization, demonstrating the core GitOps workflow.