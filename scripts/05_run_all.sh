#!/usr/bin/env bash
set -euo pipefail

echo "==> Phase 1: GCP bootstrap"
bash scripts/01_gcp_bootstrap.sh

echo "==> Phase 2: Install IDP"
bash scripts/02_install_idp.sh

echo "==> Phase 3: Install ArgoCD and app definitions"
bash scripts/03_install_argocd.sh
bash scripts/03_apply_argocd_apps.sh

echo "==> Phase 4: Install Observability"
bash scripts/04_install_observability.sh

echo "==> Completed core stack installation"
