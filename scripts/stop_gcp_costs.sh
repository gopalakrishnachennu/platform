#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-chennu-platform}"
ZONE="${ZONE:-us-central1-a}"
CLUSTER_NAME="${CLUSTER_NAME:-platform-lab}"

echo "Deleting cluster ${CLUSTER_NAME} in ${ZONE} (project: ${PROJECT_ID})..."
gcloud container clusters delete "${CLUSTER_NAME}" \
  --zone "${ZONE}" \
  --project "${PROJECT_ID}" \
  --quiet

echo "Cluster deleted. GKE compute cost should now be stopped."
