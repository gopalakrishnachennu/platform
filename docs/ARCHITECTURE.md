# Architecture

## Provisioning flow (IDP → GCP → Argo CD)

```
Backstage (IDP)
    → Software Template opens a PR with Terraform under infra/
    → Review & merge to main
    → GitHub Actions: terraform apply in GCP, then regenerate GitOps manifests from terraform output
    → Bot commits updated YAML to the same repo
    → Argo CD syncs gitops/overlays/dev
    → You see workloads + generated ConfigMaps + Application info in Argo CD
```

**Visibility:** Argo CD shows **Kubernetes objects from Git**. Terraform outputs (bucket names, VPC fields) are written into ConfigMaps and `Application.spec.info` by CI so the UI reflects what was provisioned in GCP.

**Constraint:** Argo does not call the GCP API. If something exists only in the console and not in this repo, it will not appear in Argo.

## Components

| Layer | Role |
|-------|------|
| IDP | Backstage templates in `templates/` — PR with `infra/...` |
| GCP | Resources created by Terraform; state in GCS |
| GitHub | Source of truth; Actions run build + Terraform + Git writes |
| GKE | Argo CD, runtime app, optional Backstage |
| GitOps | `gitops/` — Argo Application watches `gitops/overlays/dev` |

## Workflows

| File | When it runs |
|------|----------------|
| `ci-cloudbuild.yml` | Push to `main` — image build, deployment manifest update |
| `infra-terraform.yml` | Changes under `infra/` — apply, regenerate GitOps, Argo sync job |
| `gitops-argoc-refresh.yml` | Changes under `gitops/` or `argocd/` without touching `infra/` |

## Operator setup

- GitHub secret **`GCP_CREDENTIALS`** (service account with Cloud Build, GCS state, GKE, Terraform).
- One-time: install Argo CD, optional observability and Backstage on the cluster (Cloud Shell + `kubectl`/`helm`), then apply `argocd/dev-app.yaml`.
- Set workflow `env` (project, cluster, zone) to match your GCP project.
- Configure `idp/backstage-values-dev.yaml` for your Backstage URL and catalog Git location before installing Backstage.
