# Lab 2 - Deploy DEV

## Objective
Deploy the existing Helm chart into DEV through GitOps.

## Validate Helm
```bash
helm lint helm/nginx-demo
helm template dev helm/nginx-demo -f helm/nginx-demo/values.yaml -f apps/dev/values-dev.yaml
```

## Commit
```bash
git add .
git commit -m "Deploy DEV"
git push
```

## Verify
```bash
kubectl get applications -n argocd
kubectl get pods -n gitops-dev
kubectl get svc -n gitops-dev
```
