#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing ArgoCD in gitops namespace"
kubectl create namespace gitops --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n gitops -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD server"
kubectl rollout status deployment/argocd-server -n gitops --timeout=600s

echo "==> Initial ArgoCD admin password"
kubectl -n gitops get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
echo
echo
echo "Access UI with:"
echo "kubectl port-forward svc/argocd-server -n gitops 8080:443"
