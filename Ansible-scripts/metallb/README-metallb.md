# MetalLB deployment on EKS Anywhere

This playbook installs MetalLB for LoadBalancer services used by applications such as ArgoCD on an EKS Anywhere cluster.

## Prerequisites

- `kubectl` installed and configured to the EKS Anywhere cluster
- `ansible` installed
- `KUBECONFIG` set or configure `kubeconfig_path` in the playbook

## Usage

```bash
ansible-playbook -i ansible/hosts.ini ansible/metallb-install.yml
```

Or set kubeconfig first:

```bash
export KUBECONFIG=/path/to/your/eks-anywhere-kubeconfig
ansible-playbook -i ansible/hosts.ini ansible/metallb-install.yml
```

## Variables

You can edit these values in `metallb-install.yml`:

```yaml
metallb_namespace: metallb-system
metallb_version: v0.14.9
metallb_ip_range: "192.168.10.180-192.168.10.220"
```

This IP range should match the subnet available to your environment.

## Notes

MetalLB is required when you want Kubernetes `LoadBalancer` services like ArgoCD to receive an external IP on a bare-metal or lab network.
