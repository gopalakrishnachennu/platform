# Platform

Internal platform on **GCP** and **GitHub**: **Backstage** provisions via Terraform PRs; **Argo CD** deploys from Git; **GitHub Actions** builds images and applies infrastructure.

**Architecture:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

**Backstage:** [`idp/README.md`](idp/README.md) · [`templates/README.md`](templates/README.md)

| Path | Role |
|------|------|
| `templates/` | IDP templates + `all.yaml` Location |
| `infra/` | Terraform (created by templates + merge) |
| `gitops/` | Argo CD manifests |
| `argocd/` | Argo `Application` |
| `.github/workflows/` | CI/CD |
