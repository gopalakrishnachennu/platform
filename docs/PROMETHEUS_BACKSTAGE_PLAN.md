# Prometheus via Backstage — Implementation plan

## Goal

Provision monitoring from Backstage UI so a merge to `main` installs Prometheus/Grafana on GKE and exposes Cloud Monitoring data in Grafana.

## Design

1. Backstage template (`templates/gke-prometheus-monitoring/template.yaml`) creates a PR that adds an Argo CD `Application` YAML in `argocd/`.
2. Argo CD `Application` (`prometheus-app.yaml` skeleton) installs `kube-prometheus-stack` chart from prometheus-community.
3. Workflow updates ensure `argocd/*.yaml` files are applied (not just `dev-app.yaml`).
4. Grafana is preconfigured with `stackdriver` datasource for the selected GCP project.

## Runtime flow

Backstage Create -> PR with `argocd/prometheus-app.yaml` -> merge to `main` -> `gitops-argoc-refresh.yml` applies `argocd/` -> Argo CD creates monitoring app -> Helm chart installs Prometheus/Grafana.

## Inputs from Backstage form

- `gcpProjectId`
- `chartVersion`
- `appName`
- `namespace`
- `grafanaAdminPassword`

## Google Managed Prometheus (GMP) → Cloud Monitoring

In-cluster **kube-prometheus-stack** scrapes into a local Prometheus TSDB; that alone does **not** copy those series into **Cloud Monitoring**.

For **Cloud Monitoring** (metrics explorer, alerts, Grafana Stackdriver datasource on GCP metrics), use **GMP collection**:

1. Apply Terraform `infra/gke-monitoring/prometheus` so the cluster has `managed_prometheus { enabled = true }`.
2. Sync Argo app **`monitoring-gmp`** (`argocd/monitoring-gmp.yaml`) so `gitops/monitoring-gmp/` applies `PodMonitoring` / `ClusterPodMonitoring` objects.
3. In **Google Cloud Console → Observability → Metrics explorer**, use **Prometheus** or **Kubernetes** filters; allow a few minutes after sync.

Grafana’s **Google Cloud Monitoring** datasource reads **from** Cloud Monitoring; GMP ingestion populates that side.

## Validation checklist

- Argo CD UI shows new app (`appName`) in `gitops` namespace.
- Namespace (`namespace`) contains `prometheus`/`grafana` pods.
- Grafana UI -> datasource `Google Cloud Monitoring` exists.
- Optional: Argo app **`monitoring-gmp`** is **Synced**; Metrics explorer shows Prometheus-target data after GMP is enabled.

## Security follow-up

- Replace default `grafanaAdminPassword`.
- Rotate leaked tokens immediately.
- Move sensitive values to Kubernetes Secret / External Secrets.
