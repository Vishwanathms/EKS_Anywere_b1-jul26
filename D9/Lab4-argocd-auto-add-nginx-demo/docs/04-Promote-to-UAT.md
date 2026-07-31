# Lab 4 - Promote to UAT

## Create
```
apps/uat/values-uat.yaml
```

Commit and push.

```bash
git add .
git commit -m "Promote to UAT"
git push
```

Verify:
```bash
kubectl get applications -n argocd
kubectl get pods -n gitops-uat
```
