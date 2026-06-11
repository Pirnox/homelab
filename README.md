# homelab

GitOps repository for migrating homelab services from Proxmox LXC/Docker to **k3s** (Kubernetes), managed by **ArgoCD** and provisioned with **OpenTofu/Terraform**.

## Infrastructure

| Host | IP | Role |
|---|---|---|
| hsrv01 (Proxmox) | 192.168.1.248 | Hypervisor — i9-9700K, 32 GB RAM |
| TrueNAS VM | 192.168.1.151 | Storage, NFS shares for media |
| k3s VM | 192.168.1.245 | Kubernetes cluster (migration target) |
| Docker LXC (CT107) | 192.168.1.121 | Current Docker host (being phased out) |
| WireGuard CT (CT108) | — | VPN, exposes Jellyfin & Navidrome externally |

## Services

| Service | Namespace | Description |
|---|---|---|
| AdGuard Home | `dns` | DNS with ad-blocking, replaces Pi-hole + Unbound |
| Jellyfin | `media` | Media server |
| Navidrome | `media` | Music streaming server |
| ingress-nginx | `ingress-nginx` | Ingress controller (NodePort 30080/30443) |

## Repository Structure

```
homelab/
├── argocd/
│   └── apps.yaml          # App of Apps — ArgoCD root application
├── apps/
│   ├── adguard/           # AdGuard Home manifests
│   ├── jellyfin/          # Jellyfin manifests
│   └── navidrome/         # Navidrome manifests
└── infrastructure/
    ├── ingress-nginx/     # Helm values for ingress-nginx
    └── nfs/               # Shared NFS PersistentVolume (TrueNAS)
```

## Design Decisions

- **DNS**: AdGuard Home with `hostNetwork: true` — pod binds port 53 directly to the node IP (192.168.1.245), replacing two LXC containers.
- **Storage**: NFS PersistentVolumes from TrueNAS (`ReadOnlyMany` for media, `Retain` reclaim policy — data is never deleted automatically).
- **Ingress**: nginx-ingress via NodePort, hostname routing for `jellyfin.lan`, `navidrome.lan`, `adguard.lan`.
- **GitOps**: App of Apps pattern — ArgoCD auto-sync enabled, `prune: false` for safety during initial migration.

## Deployment Phases

1. **ingress-nginx** — install via Helm, verify with `curl http://192.168.1.245:30080` (expect 404)
2. **AdGuard Home** — deploy pod, configure upstream DNS, then switch router DNS to 192.168.1.245
3. **Jellyfin + Navidrome** — verify NFS mounts first, then deploy
4. **WireGuard update** — point CT108 endpoints from 192.168.1.121 → 192.168.1.245
5. **Decommission old LXCs** — CT100, CT104, CT107 after new services are stable

## Quick Commands

```bash
# Connect to k3s node
ssh user@192.168.1.245
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# ArgoCD CLI login
argocd login 192.168.1.245:32072 --username pirnox --insecure

# Check all pods
kubectl get pods -A

# Test AdGuard DNS
dig @192.168.1.245 google.com
```

## Conventions

- Labels: `app.kubernetes.io/name` and `app.kubernetes.io/part-of: homelab` on every manifest
- Images: pinned to explicit tags (no `latest`)
- `resources.requests` and `resources.limits` required in every Deployment
- Secrets: created manually via `kubectl create secret`; Sealed Secrets or SOPS planned
- **Do not** run `kubectl apply` manually on files under `apps/` — ArgoCD owns those
