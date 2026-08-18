
# Part 14 – Restore the Namespace

List backups:

```bash
velero backup get
```

Restore:

```bash
velero restore create \
  --from-backup backup-demo
```

Check:

```bash
velero restore get
```

Then:

```bash
velero restore describe <RESTORE_NAME>
```

---

# Part 15 – Verify Namespace Restoration

```bash
kubectl get all -n backup-demo
```

Check PVC:

```bash
kubectl get pvc -n backup-demo
```

Expected:

```text
NAME       STATUS   VOLUME
demo-pvc   Bound    pvc-xxxxxxxx
```

Check pod:

```bash
kubectl get pods -n backup-demo
```

---