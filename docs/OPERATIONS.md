# Operations (cloud only)

Use **Google Cloud Shell** (browser) or **CI/CD** — not a local Mac/Windows setup.

## Prerequisites (GCP)

- Project with billing (e.g. `chennu-platform`)
- GKE cluster (e.g. `platform-lab` in `us-central1-a`)
- GitHub **secret** `GCP_CREDENTIALS` with a service account that can: Cloud Build, GCS, Artifact Registry, GKE, Terraform

## One-time cluster software (Cloud Shell)

From **Cloud Shell** with `kubectl` configured (`gcloud container clusters get-credentials …`):

1. **Argo CD** — install from upstream manifests or Helm; apply `argocd/dev-app.yaml` from this repo.
2. **Observability** — `helm install` kube-prometheus-stack + Loki using values in `monitoring/kube-prometheus-values.yaml` (optional).
3. **Backstage** — `helm install` with `idp/backstage-values-dev.yaml` (set public URLs, not localhost).

Set **Backstage** `baseUrl` / `backend.baseUrl` to your **Ingress hostname** or internal load balancer URL.

## Day-to-day

- **Git push** to `main` drives **GitHub Actions** and **Argo CD** — no manual `kubectl` for normal changes.
- **GCP Console** — buckets, IAM, billing, GKE UI.
- **Argo CD / Grafana** — expose with **Ingress** or use **kubectl port-forward from Cloud Shell** only (not required on a laptop).

## Alerting (Grafana)

After Grafana is reachable (Ingress or port-forward from Cloud Shell): **Alerting → Contact points** → PagerDuty or Webhook → **Test**.

## GitHub workflows

| Workflow | Role |
|----------|------|
| `ci-cloudbuild.yml` | Build & push image; patch GitOps deployment |
| `infra-terraform.yml` | Terraform + regenerate GitOps + Argo sync job |
| `gitops-argoc-refresh.yml` | Apply Argo Application + hard refresh on gitops-only pushes |
