Lab 2
Convert to Helm

Current repo

deployment.yaml
service.yaml
ingress.yaml

Convert into

gitops-nginx/

charts/

nginx-demo/

Chart.yaml

values.yaml

templates/

deployment.yaml

service.yaml

ingress.yaml

_helpers.tpl

Now every value moves into

values.yaml

Example

company: Vishwacloudlab

application: GitOps Demo

version: v1.0

environment: DEV

color: blue

replicas: 2

Deployment uses

{{ .Values.company }}

{{ .Values.environment }}

{{ .Values.version }}

Students learn

Git Commit

↓

values.yaml

↓

ArgoCD

↓

Helm Template

↓

Deploy

This is how nearly every production GitOps repository works.

=============== Lab instructions
Validate the Helm Chart
cd charts/nginx-demo

helm lint .

Expected output:

==> Linting .
1 chart(s) linted, 0 chart(s) failed
Render the Templates
helm template nginx-demo .

This generates Kubernetes YAML locally without deploying.

Install with Helm (Local Testing)
helm install nginx-demo .

Verify:

kubectl get all
kubectl get ingress
Upgrade
helm upgrade nginx-demo .
Uninstall
helm uninstall nginx-demo
ArgoCD Application

Point ArgoCD to:

Repository
    ↓
gitops-nginx
    ↓
charts/nginx-demo

ArgoCD automatically detects it is a Helm chart and executes:

helm template
        ↓
Generated Kubernetes YAML
        ↓
Compare Live State
        ↓
Sync
        ↓
Deploy
Student Exercise 1

Open values.yaml.

Change:

version: v1.0.0

to:

version: v1.1.0

Commit:

git add .
git commit -m "Upgrade to v1.1.0"
git push

Result:

Git Push
      ↓
ArgoCD detects commit
      ↓
Helm renders templates
      ↓
Deployment updated
      ↓
New ReplicaSet
      ↓
New Pod
      ↓
Browser

Version : v1.1.0
Student Exercise 2

Increase replicas:

replicas: 3

Commit:

git commit -am "Scale application"
git push

Verify:

kubectl get pods

Three Pods should be running.

Student Exercise 3

Modify:

environment: Production

color: Green

buildDate: "31-Jul-2026"

Commit:

git commit -am "Production release"
git push

Refresh the browser and observe the updated values.