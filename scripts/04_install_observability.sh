#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing kube-prometheus-stack"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

if ! helm status kube-prometheus -n monitoring >/dev/null 2>&1; then
  helm install kube-prometheus prometheus-community/kube-prometheus-stack -n monitoring \
    -f monitoring/kube-prometheus-values.yaml
else
  echo "==> Upgrading kube-prometheus-stack (Grafana alerting + values)"
  helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack -n monitoring \
    -f monitoring/kube-prometheus-values.yaml \
    --reuse-values
fi

echo "==> Installing Loki stack"
if ! helm status loki -n monitoring >/dev/null 2>&1; then
  helm install loki grafana/loki-stack -n monitoring --set promtail.enabled=true
fi

echo "==> Fixing Loki datasource default conflict for Grafana"
if kubectl get configmap loki-loki-stack -n monitoring >/dev/null 2>&1; then
  kubectl get configmap loki-loki-stack -n monitoring -o yaml \
    | sed 's/isDefault: true/isDefault: false/g' \
    | kubectl apply -f -
fi

kubectl rollout restart deployment/kube-prometheus-grafana -n monitoring

echo "==> Waiting for Grafana deployment"
kubectl rollout status deployment/kube-prometheus-grafana -n monitoring --timeout=600s

echo "==> Applying baseline alert rules"
kubectl apply -f monitoring/prometheus-rules.yaml

echo "==> Grafana admin password"
kubectl get secret -n monitoring kube-prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo
echo
echo "Access Grafana with:"
echo "kubectl port-forward svc/kube-prometheus-grafana -n monitoring 3000:80"
