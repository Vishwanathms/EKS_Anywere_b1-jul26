# EKS Anywhere (vSphere) — Setup Prerequisites & Pre-Flight Checklist

Compiled from the issues hit while bringing up `production-cluster-l31`. Intended to be run
through **before** starting `eksctl anywhere create cluster` for every future cluster in this
lab (4 more are planned), so the same failures aren't repeated one-by-one per cluster.

Every item below is traced back to a real failure encountered — see
`troubleshooting-log.md` and `cluster-handoff-runbook.md` for the full incident detail.

---

## 1. vCenter account & permissions

- [ ] The vSphere account used for `GOVC_USERNAME` / `EKSA_VSPHERE_USERNAME` must have the **full**
  privilege set documented at
  https://anywhere.eks.amazonaws.com/docs/getting-started/vsphere/vsphere-preparation/ — not just
  enough to clone/power VMs.
  **Verify before starting**, not after:
  ```bash
  eksctl anywhere create cluster -f cluster.yaml --dry-run 2>&1  # if supported by CLI version
  # or run the real command once with -v 3 and read the full missing-permissions list:
  eksctl anywhere create cluster -f cluster.yaml -v 3
  ```
  *Why:* `student-31@vsphere.local` was missing at least one privilege from the full set
  (confirmed: it lacks `Resource pool → Modify`). This only surfaced as a late pre-flight failure
  (`validating vsphere user privileges`) — after everything else had already passed — because the
  account has enough rights to do the actual work (clone/power VMs) but not everything EKS-A's
  validator checks for. Get the exact list with `-v 3` *before* the real attempt, not by
  discovering the flag `--skip-validations=vsphere-user-privilege` exists after the fact.

- [ ] If the account is expected to remain permission-limited going forward (shared student lab),
  document which specific validations will always need `--skip-validations=<name>` /
  `--skip-ip-check`, so every future cluster's run command is correct from the start instead of
  discovered through trial and error.

---

## 2. Resource pool capacity planning

- [ ] **Compute the full desired footprint before touching vCenter:**
  ```
  desired_memory_MiB = sum over all machine groups of (memoryMiB × count)
  ```
  For this cluster: control plane (2 × 8192) + etcd (3 × 8192) + workers (2 × 8192) = **57,344 MiB**.

- [ ] **Resource pool `Mem Limit` must exceed `current pool Mem Usage + desired_memory_MiB`**, with
  a safety margin (at least 10–15%) — not just exceed `desired_memory_MiB` alone.
  *Why:* the EKS-A pre-flight validator checks `(Limit − current Usage) >= desired_memory_MiB`. It
  does **not** know that VMs already existing under that pool don't need "new" memory — so this
  check can fail even when the cluster is already healthy and running. We hit this twice (raised
  64GB → 75.5GB, still short; → 90.9GB, passed). **Size for this from the start** rather than
  iterating live:
  ```
  Mem Limit >= (current pool usage) + desired_memory_MiB × 1.15   (rough safety margin)
  ```

- [ ] **Check who can actually change the resource pool limit before you need to.** The
  provisioning account (`student-*@vsphere.local`) does **not** have `Resource pool → Modify`
  rights — confirmed via a denied `govc pool.change`. Raising the limit requires a separate
  admin-privileged account. Identify that account/contact **before** starting, not mid-incident.

- [ ] **Check physical host capacity and sibling resource pools before raising any limit**, especially
  in a shared lab:
  ```bash
  govc find /LAB-DC/host -type c
  govc find /LAB-DC/host/<cluster>/Resources -type p
  for p in $(govc find /LAB-DC/host/<cluster>/Resources -type p); do
    govc pool.info -dc <DC> "$p" | grep -E "Path:|Mem Usage|Mem Limit"
  done
  ```
  In this lab: 12 identical 64GB-limit pools exist, sized so their sum ≈ total physical capacity
  (~768GB across 2 ESXi hosts), on the assumption usage stays staggered across students. **If 4
  more clusters are coming, don't raise limits ad hoc per-incident — decide a standard sizing (e.g.
  a fixed 90–96GB limit per pool if that's what an EKS-A cluster of this shape needs) and apply it
  consistently up front**, and keep an eye on whether pools are actually staying staggered in
  practice as more students come online.

---

## 3. Networking

- [ ] **Pod and Service CIDRs in `cluster.yaml` must not overlap the physical vSphere network in
  any way.** This was the single largest root cause in this session (10-minute hangs, then a full
  reconciler deadlock).
  - Check the real LAN's subnet(s) first (here: `192.168.1.0/24`, hosting vCenter and the
    control-plane endpoint).
  - Never use a `/16` or larger for `pods.cidrBlocks` that could swallow that subnet — e.g.
    `192.168.0.0/16` silently contains `192.168.1.0/24`. This is the EKS-A default in some
    generated templates and is a trap specifically when the physical network also happens to be in
    `192.168.x.x`.
  - Confirmed working values for this lab: `pods: 10.244.0.0/16`, `services: 10.96.0.0/12` (also
    check these two don't overlap each other, and don't overlap any VPN/other private range in use
    on this network).

- [ ] **`VSphereDatacenterConfig.spec.server` (the vCenter hostname) must resolve correctly from
  every VM on the vSphere network — not just from the admin's workstation.**
  - Test this explicitly, from a VM, before relying on it:
    ```bash
    ssh -i <key> ec2-user@<any-existing-vm-ip> "getent hosts <vcenter-hostname>"
    ```
  - A hostname that only resolves via a manual `/etc/hosts` entry on the workstation running the
    CLI **will pass every CLI pre-flight check** (since those run via `docker exec --network host`,
    inheriting the workstation's `/etc/hosts`) but **will fail inside the cluster** — specifically
    breaking `vsphere-cloud-controller-manager`, which is a hard blocker (it sets `Node.spec.providerID`,
    without which CAPI can never mark machines healthy). This failure mode is silent and easy to
    misdiagnose as a Cilium/CNI/node-readiness problem instead of DNS, because the symptoms are
    several hops downstream of the actual cause.
  - **Fix at the network's real DNS resolver**, not with `/etc/hosts` — a per-machine hosts-file
    workaround does not scale past the one workstation it's set on.

- [ ] **Control-plane endpoint IP** (`controlPlaneConfiguration.endpoint.host`) must be:
  - Free and unused at cluster-creation time (outside any DHCP range, not assigned to another host)
  - On the same L2 subnet/VLAN as the nodes (kube-vip uses ARP)
  - Documented per-cluster if multiple clusters share the same subnet, to avoid collisions across
    the 4 upcoming clusters

---

## 4. CLI environment / shell setup

- [ ] **Both `GOVC_*` and `EKSA_VSPHERE_*` environment variables are required, and are not the
  same thing.** `GOVC_USERNAME`/`GOVC_PASSWORD` (used by pre-flight `govc` checks) may already be
  in `~/.bashrc`, but `EKSA_VSPHERE_USERNAME`/`EKSA_VSPHERE_PASSWORD` (required by the actual
  `eksctl anywhere` binary) are a **separate** pair the CLI needs and are easy to forget if they
  were only ever `export`ed manually in an interactive shell rather than saved anywhere. **Add
  both pairs to a checked-in (but gitignored/secret-safe) env file or `~/.bashrc`** so every future
  invocation — including from automation/tooling, not just an interactive terminal — has them:
  ```bash
  export GOVC_URL='vcenter.vishwacloudlab.in'
  export GOVC_USERNAME='student-31@vsphere.local'
  export GOVC_PASSWORD='...'
  export GOVC_INSECURE=1
  export GOVC_DATACENTER='LAB-DC'
  export EKSA_VSPHERE_USERNAME="$GOVC_USERNAME"
  export EKSA_VSPHERE_PASSWORD="$GOVC_PASSWORD"
  ```

- [ ] **Run `create cluster` from a persistent/logged shell (e.g. `tmux`, `screen`, or as a proper
  background job with output redirected to a log file from the start)**, not a shell whose state
  might not persist. A run that dies partway (terminal closed, tool restarted) leaves a stale
  bootstrap `kind` cluster and a checkpoint file that — as observed in this session — cannot be
  reliably trusted to resume correctly. Treat every `create cluster` invocation as **all-or-nothing**:
  let it run to completion or deliberate failure in one continuous session, and if it does fail
  partway, clean up (see §6) before retrying rather than assuming resume will work.

---

## 5. VM template / OS prerequisites

- [ ] Confirm the Bottlerocket template matching the target Kubernetes version already exists in
  vCenter before creating the cluster (`govc find /LAB-DC -type VirtualMachine -name
  bottlerocket-...`). EKS-A will build it automatically if missing, but that adds significant time
  to the first run and is worth doing as a separate, isolated step so template-build failures don't
  get conflated with cluster-provisioning failures.

- [ ] Confirm SSH key material referenced in `cluster.yaml` (`sshAuthorizedKeys`) has a
  corresponding private key available locally for troubleshooting — this was essential for
  diagnosing Problems 2 and 3 by SSHing directly into VMs. Don't skip setting this even for
  "throwaway" clusters.

---

## 6. If a `create cluster` run fails partway through provisioning

This lab's checkpoint/resume behavior was **not reliable** once a run reached actual task
execution (as opposed to failing during pre-flight validation, which is safe to retry freely).
Before retrying a run that got past `setup-validate`:

- [ ] Check for a leftover bootstrap `kind` cluster:
  ```bash
  docker ps -a | grep eks-a-cluster-control-plane
  kind get clusters
  ```
- [ ] If one exists and holds state you need (i.e. the workload cluster it was managing is already
  partially or fully provisioned), **do not let a retry blindly create a new one under the same
  name** — a fresh bootstrap cluster will generate entirely new CAPI object identities that won't
  match already-existing VMs, risking duplicate VM creation and control-plane-endpoint (kube-vip)
  collisions. Assess cluster health directly first (extract the workload kubeconfig from the
  bootstrap cluster's `<cluster-name>-kubeconfig` secret in `eksa-system` and check node status)
  before deciding whether to resume, manually complete the handoff (see
  `cluster-handoff-runbook.md`), or clean up and start over.
- [ ] If starting over is genuinely the right call (nothing salvageable), fully tear down first:
  ```bash
  kind delete cluster --name <cluster-name>-eks-a-cluster
  docker ps -a --format '{{.Names}}' | grep '^eksa_' | xargs -r -I{} docker rm -f {}
  rm -f <cluster-name>/generated/<cluster-name>-checkpoint.yaml
  ```
  and only then re-run `create cluster` from a clean slate.

---

## Quick pre-flight checklist (run through this before every future `create cluster`)

1. [ ] `cluster.yaml` pod/service CIDRs confirmed disjoint from the real vSphere network
2. [ ] vCenter hostname resolves correctly from an existing VM on the same network (not just the
   workstation)
3. [ ] Control-plane endpoint IP confirmed free and not colliding with another cluster in the lab
4. [ ] Resource pool `Mem Limit` computed and set ≥ (current usage + full desired footprint × 1.15)
   *before* starting, by an account with `Resource pool → Modify` rights
5. [ ] `EKSA_VSPHERE_USERNAME` / `EKSA_VSPHERE_PASSWORD` exported in the shell that will run the
   command (not assumed inherited from `.bashrc`)
6. [ ] Ran `-v 3` once (or otherwise confirmed) to know in advance which `--skip-validations=...`
   flags this account will always need
7. [ ] Command will run in a persistent session (`tmux`/background with logging) so a dropped
   connection doesn't leave a half-finished run
8. [ ] No stale bootstrap `kind` cluster from a previous attempt still running under the target
   cluster's name
