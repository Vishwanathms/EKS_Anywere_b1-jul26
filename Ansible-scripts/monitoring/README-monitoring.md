# Monitoring stack installation on EKS Anywhere

This playbook installs a basic monitoring stack on the EKS Anywhere cluster:

- Prometheus
- Grafana
- Loki

## Prerequisites

- `kubectl` configured to the cluster
- `helm` installed
- `ansible` installed
- MetalLB already installed so LoadBalancer services can get external IPs

## Usage

```bash
export KUBECONFIG=~/.kube/config
ansible-playbook -i ansible/hosts.ini ansible/monitoring-install.yml
```

## Default values

The playbook uses the `monitoring` namespace and assigns the external IP to the LoadBalancer services.

```yaml
monitoring_ns: monitoring
external_ip: "192.168.230.92"
```

## Access

- Prometheus: `http://192.168.230.92:9090`
- Grafana: `http://192.168.230.92:80`
- Loki: `http://192.168.230.92:3100`

Grafana credentials:

- username: `admin`
- password: `admin123`

## Notes

This is a lab-friendly installation and should be adjusted for production security and resource sizing.
