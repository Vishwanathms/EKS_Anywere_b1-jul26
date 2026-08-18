
# Part 5 – Install Velero

For your lab, I recommend installing Velero with **Node Agent / File System Backup enabled**.

Why?

Your students are on **vSphere/on-premises storage**, so you shouldn't assume that a cloud-provider-specific volume snapshot mechanism is available.

Velero's File System Backup can back up volumes at the filesystem level and is useful for storage types without a native Velero snapshot implementation. ([Velero][3])

Velero enables this with:

```bash
--use-node-agent
```

([Velero][4])

---

# Part 6 – Install Velero CLI

Download the appropriate Velero release for the admin machine.

Verify:

```bash
velero version --client-only
```

You should see something similar to:

```text
Client:
    Version: v1.x.x
```

Then make sure the correct EKS Anywhere kubeconfig is active:

```bash
export KUBECONFIG=/path/to/<cluster>-eks-a-cluster.kubeconfig
```

Verify:

```bash
kubectl get nodes
```

---

# Part 7 – Prepare MinIO

This is where your existing **MinIO on EKS Anywhere** work fits nicely.

Create a bucket:

```text
velero
```

For example:

```text
MinIO
  |
  +-- velero
       |
       +-- backups
       +-- kopia
```

You will need:

```text
MinIO endpoint
Access key
Secret key
Bucket name
```

Example:

```text
Endpoint: http://MINIO_IP:9000
Bucket: velero
```

Don't use these example credentials literally.

---

# Part 8 – Create Velero Credentials

Create:

```bash
cat > credentials-velero <<EOF
[default]
aws_access_key_id=MINIO_ACCESS_KEY
aws_secret_access_key=MINIO_SECRET_KEY
EOF
```

Protect it:

```bash
chmod 600 credentials-velero
```

---

# Part 9 – Install Velero with MinIO

For an S3-compatible MinIO endpoint, use the AWS plugin and configure the endpoint appropriately.

Conceptually:

```bash
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:<VERSION> \
  --bucket velero \
  --secret-file ./credentials-velero \
  --backup-location-config \
    region=minio,\
    s3ForcePathStyle="true",\
    s3Url=http://MINIO_IP:9000 \
  --use-node-agent \
  --default-volumes-to-fs-backup
```

The exact plugin version should be matched to the Velero version you install.

`--use-node-agent` installs the Velero Node Agent for File System Backup, while `--default-volumes-to-fs-backup` makes pod volumes use FSB by default. ([Velero][3])

---

# Part 10 – Verify Velero

```bash
kubectl get pods -n velero
```

You should see:

```text
velero-xxxxxxxxxx
node-agent-xxxxx
node-agent-xxxxx
...
```

Check:

```bash
velero version
```

Then:

```bash
velero backup-location get
```

Expected:

```text
NAME      PROVIDER   BUCKET/PREFIX
default   aws        velero
```

Check:

```bash
velero backup-location get default -o yaml
```

The location should show:

```text
phase: Available
```

---

# Part 11 – First Backup

Create a namespace backup:

```bash
velero backup create backup-demo \
  --include-namespaces backup-demo
```

Check:

```bash
velero backup get
```

Then:

```bash
velero backup describe backup-demo
```

For more details:

```bash
velero backup describe backup-demo --details
```

---

# Part 12 – Verify PV Backup

This is one of the most important parts of the lab.

Check:

```bash
velero backup describe backup-demo --details
```

Students should identify:

```text
Namespaces
Pods
Deployments
Services
PVC
PV
Pod Volume Backup
```

Check the node-agent volume backups:

```bash
kubectl get podvolumebackups \
  -n velero \
  -l velero.io/backup-name=backup-demo
```

Velero documents `PodVolumeBackup` resources as a way to verify filesystem-based volume backups. ([Velero][3])

---

# Part 13 – Simulate Disaster

Now make the lab interesting.

Delete the application:

```bash
kubectl delete namespace backup-demo
```

Verify:

```bash
kubectl get namespace backup-demo
```

Expected:

```text
Error from server (NotFound)
```

The following are now gone:

```text
Namespace
Deployment
Pod
PVC
PV
Application data
```

---
