# Lab 3 - Promote to TEST

## Create Environment
Create:
```
apps/test/values-test.yaml
```

Copy values from DEV and modify environment specific values.

## Commit
```bash
git add .
git commit -m "Promote to TEST"
git push
```

## Verify
```bash
kubectl get applications -n argocd
kubectl get ns
kubectl get pods -n gitops-test
```

Expected:
- test Application created automatically.
- gitops-test namespace created.
