#!/usr/bin/env bash
set -euo pipefail

echo "==> Applying ArgoCD applications"
kubectl apply -f argocd/dev-app.yaml

echo "==> Current ArgoCD applications"
kubectl get applications.argoproj.io -n gitops
