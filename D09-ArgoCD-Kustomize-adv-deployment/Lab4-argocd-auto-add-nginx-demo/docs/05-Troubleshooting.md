# Troubleshooting

## Application Missing
- Verify ApplicationSet exists.
- Check Git repository URL and branch.

## OutOfSync
- Inspect ArgoCD UI.
- Check rendered manifests:
```bash
helm template ...
```

## CrashLoopBackOff
```bash
kubectl logs <pod> -n <namespace>
kubectl describe pod <pod> -n <namespace>
```
