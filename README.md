# Platform (GCP + GitHub)

**Minimal cloud-native platform:** GitHub Actions + GKE + Argo CD + Terraform.  
**No local scripts** — automation runs in GitHub; cluster work uses **Google Cloud Shell** or your pipeline.

## What this repo is

| Piece | Purpose |
|-------|---------|
| `gitops/` | What Argo CD deploys to GKE (`dev` namespace) |
| `argocd/` | Argo CD `Application` CR |
| `infra/` | Terraform (GCS buckets, etc.) — state in GCS |
| `.github/workflows/` | Build + Terraform + Argo refresh |
| `templates/` | Backstage Software Templates (GCP) |
| `idp/` | Helm values for Backstage (set **public URLs**, not localhost) |
| `monitoring/` | Prometheus rules + Grafana Helm values |
| `app/` | Application source built by Cloud Build |

## Architecture

→ **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** (diagram + flows)

## Operations

→ **[`docs/OPERATIONS.md`](docs/OPERATIONS.md)** (Cloud Shell, secrets, optional Helm installs)

## Requirements

- GCP project, GKE cluster, Artifact Registry repo (see `OPERATIONS.md`)
- GitHub secret **`GCP_CREDENTIALS`** for workflows

## Naming (dev)

- Argo app: **`platform-api-dev`**
- Workload: **`platform-api`** in namespace **`dev`**

## Cost

Prefer a small / spot node pool, no public LB unless you need one — see GCP console for spend.
