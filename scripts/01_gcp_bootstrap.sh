#!/usr/bin/env bash
set -euo pipefail

# Low-cost defaults (override with env vars if needed)
PROJECT_ID="${PROJECT_ID:-chennu-platform}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"
CLUSTER_NAME="${CLUSTER_NAME:-platform-lab}"
NODES="${NODES:-1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"

echo "==> Validating gcloud authentication"
if ! gcloud auth list --format="value(account)" | awk 'NF{found=1} END{exit !found}'; then
  echo "No active gcloud account found."
  echo "Run: gcloud auth login --no-launch-browser"
  exit 1
fi

echo "==> Setting active project to ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

echo "==> Enabling required APIs"
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

echo "==> Creating Artifact Registry repo (idempotent)"
gcloud artifacts repositories describe platform-images \
  --location "${REGION}" >/dev/null 2>&1 || \
gcloud artifacts repositories create platform-images \
  --repository-format docker \
  --location "${REGION}" \
  --description "Platform images for GitOps pipeline"

echo "==> Creating GKE cluster (low-cost spot node pool)"
if ! gcloud container clusters describe "${CLUSTER_NAME}" --zone "${ZONE}" >/dev/null 2>&1; then
  gcloud container clusters create "${CLUSTER_NAME}" \
    --zone "${ZONE}" \
    --num-nodes "${NODES}" \
    --machine-type "${MACHINE_TYPE}" \
    --spot
fi

echo "==> Fetching cluster credentials"
gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone "${ZONE}"

echo "==> Creating namespaces"
for ns in idp gitops monitoring dev; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
done

echo "==> Bootstrap complete"
kubectl get nodes
kubectl get ns | awk '/idp|gitops|monitoring|dev/'
