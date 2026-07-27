┌────────────────────────────┐
│ 1. User executes           │
│ kubectl run nginx          │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ kubectl creates HTTP POST  │
│ request to API Server      │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ API Server                 │
│ Authentication             │
│ (Who are you?)             │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Authorization (RBAC)       │
│ Can you create Pods?       │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Admission Controllers      │
│ Default values             │
│ Security Policies          │
│ Resource Validation        │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ API Server stores Pod      │
│ object in etcd             │
│ (Desired State)            │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Scheduler notices          │
│ Pod has no Node            │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Scheduler checks           │
│ CPU                        │
│ Memory                     │
│ Taints                     │
│ Affinity                   │
│ Policies                   │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Scheduler chooses Node     │
│ Example: worker-2          │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ API Server updates Pod     │
│ Spec with Node Name        │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ kubelet on worker-2        │
│ detects assigned Pod       │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ kubelet contacts           │
│ containerd                 │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Pull nginx image           │
│ if not already available   │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Create Pod Sandbox         │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ CNI Plugin                 │
│ Creates Network            │
│ Assigns Pod IP             │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Start nginx container      │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ kubelet sends status       │
│ Running                    │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ API Server updates etcd    │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ kubectl get pods           │
│ STATUS = Running           │
└────────────────────────────┘