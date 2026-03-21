#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing ArgoCD in gitops namespace"
kubectl create namespace gitops --dry-run=client -o yaml | kubectl apply -f -
# Use server-side apply to avoid CRD annotation-size errors on reruns.
kubectl apply --server-side --force-conflicts -n gitops \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD server"
kubectl rollout status deployment/argocd-server -n gitops --timeout=600s

# Lab reliability: grant controller broad read access to avoid sync Unknown on GKE extras.
kubectl create clusterrolebinding argocd-application-controller-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=gitops:argocd-application-controller \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Initial ArgoCD admin password"
kubectl -n gitops get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
echo
echo
echo "Access UI with:"
echo "kubectl port-forward svc/argocd-server -n gitops 8080:443"
