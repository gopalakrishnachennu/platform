#!/usr/bin/env bash
set -euo pipefail

# Recreate low-cost cluster and reinstall core stack.
# Safe defaults can be overridden using env vars.
PROJECT_ID="${PROJECT_ID:-chennu-platform}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"
CLUSTER_NAME="${CLUSTER_NAME:-platform-lab}"
NODES="${NODES:-1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"

echo "Starting cost-safe mode with:"
echo "  PROJECT_ID=${PROJECT_ID}"
echo "  REGION=${REGION}"
echo "  ZONE=${ZONE}"
echo "  CLUSTER_NAME=${CLUSTER_NAME}"
echo "  NODES=${NODES}"
echo "  MACHINE_TYPE=${MACHINE_TYPE}"

echo "Step 1/4: Bootstrap GCP + cluster"
PROJECT_ID="${PROJECT_ID}" \
REGION="${REGION}" \
ZONE="${ZONE}" \
CLUSTER_NAME="${CLUSTER_NAME}" \
NODES="${NODES}" \
MACHINE_TYPE="${MACHINE_TYPE}" \
bash scripts/01_gcp_bootstrap.sh

echo "Step 2/4: Install IDP (Backstage)"
bash scripts/02_install_idp.sh

echo "Step 3/4: Install ArgoCD and applications"
bash scripts/03_install_argocd.sh
bash scripts/03_apply_argocd_apps.sh

echo "Step 4/4: Install observability stack"
bash scripts/04_install_observability.sh

echo "Cost-safe start complete."
echo "Run: bash scripts/open_access_tunnels.sh"
