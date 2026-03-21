#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Backstage in idp namespace"
helm repo add backstage https://backstage.github.io/charts >/dev/null 2>&1 || true
helm repo update

if ! helm status backstage -n idp >/dev/null 2>&1; then
  helm install backstage backstage/backstage -n idp
fi

echo "==> Waiting for Backstage rollout"
kubectl rollout status deployment/backstage -n idp --timeout=600s

echo "==> Backstage is ready"
kubectl get pods -n idp
echo
echo "Access UI with:"
echo "kubectl port-forward svc/backstage 7007:7007 -n idp"
