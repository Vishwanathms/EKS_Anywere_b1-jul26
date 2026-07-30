### 1. Enable Auto Sync for the application

```yaml
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Or using the CLI:

```bash
argocd app set <app-name> \
  --sync-policy automated \
  --self-heal
```

### 2. Set the reconciliation interval to 2 minutes

Edit the `argocd-cm` ConfigMap:

```bash
kubectl edit configmap argocd-cm -n argocd
```

Add or modify:

```yaml
data:
  timeout.reconciliation: 120s
  timeout.reconciliation.jitter: 0s
```

Or apply it directly:

```bash
kubectl patch configmap argocd-cm \
  -n argocd \
  --type merge \
  -p '{
    "data": {
      "timeout.reconciliation": "120s",
      "timeout.reconciliation.jitter": "0s"
    }
  }'
```

Restart the Argo CD components if the change is not picked up automatically:

```bash
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout restart statefulset argocd-application-controller -n argocd
```

### Verify

```bash
kubectl get configmap argocd-cm -n argocd -o yaml | grep timeout.reconciliation
```

Expected output:

```text
timeout.reconciliation: 120s
timeout.reconciliation.jitter: 0s
```
