# Platform Engineering Projects (Low-Cost, No Docker)

This repository contains a low-cost implementation path for:

1. Internal Developer Platform (Backstage + Terraform)
2. GitOps Multi-Environment Pipeline (ArgoCD + GitHub Actions + Cloud Build)
3. Observability Stack (Prometheus + Grafana + Loki)

## Prerequisites

- `gcloud` installed
- `kubectl` installed
- `helm` installed
- `terraform` installed
- GCP billing enabled

## One-time auth

```bash
gcloud auth login --no-launch-browser
gcloud auth application-default login --no-launch-browser
```

## Fast run sequence

```bash
chmod +x scripts/*.sh
bash scripts/01_gcp_bootstrap.sh
bash scripts/02_install_idp.sh
bash scripts/03_install_argocd.sh
bash scripts/03_apply_argocd_apps.sh
bash scripts/04_install_observability.sh
```

## Optional all-in-one run

```bash
chmod +x scripts/*.sh
bash scripts/05_run_all.sh
```

## Terraform IDP

```bash
cd terraform-idp
terraform init
terraform apply -var="team_namespace=team-a" -var="service_account_name=team-viewer"
```

## Access URLs (via port-forward)

- Backstage: `http://localhost:7007`
- ArgoCD: `https://localhost:8080`
- Grafana: `http://localhost:3000`

## Cost controls

- Start with 1 spot node.
- Avoid cloud load balancers.
- Delete cluster when idle:

```bash
gcloud container clusters delete platform-lab --zone us-central1-a --project chennu-platform
```
