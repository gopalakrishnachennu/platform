#!/usr/bin/env bash
set -euo pipefail

# One-command cluster power toggle:
# - If node count > 0 -> pause (resize to 0)
# - If node count == 0 -> resume (resize to RESUME_NODES, default 1)
#
# Optional explicit mode:
#   bash scripts/cluster_power.sh pause
#   bash scripts/cluster_power.sh resume

PROJECT_ID="${PROJECT_ID:-chennu-platform}"
ZONE="${ZONE:-us-central1-a}"
CLUSTER_NAME="${CLUSTER_NAME:-platform-lab}"
RESUME_NODES="${RESUME_NODES:-1}"

MODE="${1:-toggle}"
if [[ "${MODE}" != "toggle" && "${MODE}" != "pause" && "${MODE}" != "resume" ]]; then
  echo "Usage: bash scripts/cluster_power.sh [toggle|pause|resume]"
  exit 1
fi

if ! gcloud container clusters describe "${CLUSTER_NAME}" --zone "${ZONE}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Cluster ${CLUSTER_NAME} not found in ${ZONE} (${PROJECT_ID})."
  echo "Run: bash scripts/start_cost_safe_mode.sh"
  exit 1
fi

CURRENT_NODES="$(gcloud container clusters describe "${CLUSTER_NAME}" \
  --zone "${ZONE}" \
  --project "${PROJECT_ID}" \
  --format='value(currentNodeCount)')"

if [[ "${MODE}" == "pause" ]]; then
  TARGET_NODES=0
elif [[ "${MODE}" == "resume" ]]; then
  TARGET_NODES="${RESUME_NODES}"
else
  if [[ "${CURRENT_NODES}" -gt 0 ]]; then
    TARGET_NODES=0
  else
    TARGET_NODES="${RESUME_NODES}"
  fi
fi

if [[ "${CURRENT_NODES}" == "${TARGET_NODES}" ]]; then
  echo "No change needed. Cluster node count already ${CURRENT_NODES}."
  exit 0
fi

if [[ "${TARGET_NODES}" -eq 0 ]]; then
  echo "Pausing cluster by scaling nodes: ${CURRENT_NODES} -> 0"
else
  echo "Resuming cluster by scaling nodes: ${CURRENT_NODES} -> ${TARGET_NODES}"
fi

gcloud container clusters resize "${CLUSTER_NAME}" \
  --zone "${ZONE}" \
  --project "${PROJECT_ID}" \
  --num-nodes "${TARGET_NODES}" \
  --quiet

echo "Done. Current node count should be ${TARGET_NODES}."
