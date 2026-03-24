# GKE Prometheus Monitoring Template

Installs `kube-prometheus-stack` through Argo CD by generating an Application manifest under `argocd/`.

## What gets created

- Argo CD `Application` in `gitops` namespace
- Helm chart source: `prometheus-community/kube-prometheus-stack`
- Target namespace: configurable (default `monitoring`)
- Grafana datasource: Google Cloud Monitoring (project from template input)

## Requirements

- Argo CD installed and able to apply `argocd/*.yaml`
- GKE cluster access from workflow (`GCP_CREDENTIALS`)
- `gitops` namespace exists (or Argo install namespace where Application CRs live)

