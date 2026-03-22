# Platform architecture (cloud-only)

Everything runs in **Google Cloud** and **GitHub**. No laptop scripts are required for normal operation.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub (source + automation)                                │
│  • Code, GitOps manifests, Terraform                         │
│  • Actions: build image, apply infra, refresh Argo           │
└──────────────────────────┬──────────────────────────────────┘
                           │ push / merge
┌──────────────────────────▼──────────────────────────────────┐
│  Google Cloud                                                │
│  • GKE — workloads                                           │
│  • Artifact Registry + Cloud Build — container images        │
│  • GCS — Terraform state + buckets                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  GKE namespaces                                              │
│  dev          → platform-api (GitOps)                        │
│  gitops       → Argo CD                                      │
│  monitoring   → Prometheus / Grafana / Loki                  │
│  idp          → Backstage (optional)                         │
└─────────────────────────────────────────────────────────────┘
```

## Flows

| Flow | What happens |
|------|----------------|
| **App deploy** | Push `main` → Cloud Build builds image → bot updates `gitops/base/deployment.yaml` → Argo syncs to `dev`. |
| **Infra** | Change `infra/**` on `main` → Terraform apply → bot regenerates GitOps + Argo Application metadata → **argocd-sync** job updates cluster. |
| **Templates** | Backstage (in cluster) opens PRs with Terraform; merge triggers same pipeline. |

## What Argo CD does

- Watches **Git** (`gitops/overlays/dev`). It does **not** read the GCP API for buckets.
- Bucket names appear in GitOps **only** after Terraform outputs are written by CI.

## Related docs

- `OPERATIONS.md` — how to run one-time installs (Cloud Shell, not your laptop).
- `../README.md` — repo entry point.
