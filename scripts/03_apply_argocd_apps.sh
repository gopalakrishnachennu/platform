#!/usr/bin/env bash
set -euo pipefail

echo "==> Applying ArgoCD applications"
kubectl apply -f argocd/dev-app.yaml
kubectl apply -f argocd/staging-app.yaml
kubectl apply -f argocd/production-app.yaml

echo "==> Current ArgoCD applications"
kubectl get applications.argoproj.io -n gitops
