# Lab 1 - Bootstrap ArgoCD

## Objective
Bootstrap ArgoCD using an ApplicationSet.

## Steps
1. Verify ArgoCD pods
```bash
kubectl get pods -n argocd
```

2. Create `bootstrap/project.yaml`.

3. Create `bootstrap/applicationset.yaml`.

4. Apply bootstrap:
```bash
kubectl apply -f bootstrap/project.yaml
kubectl apply -f bootstrap/applicationset.yaml
```

5. Verify:
```bash
kubectl get applications -n argocd
kubectl get applicationsets -n argocd
```

Expected:
- dev application created automatically.
