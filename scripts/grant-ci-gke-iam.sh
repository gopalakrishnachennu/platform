#!/usr/bin/env bash
# Grant the GitHub Actions GCP service account (GCP_CREDENTIALS) permission to
# plan/apply Terraform that reads and updates GKE (e.g. infra/gke-monitoring/*).
#
# Usage:
#   ./scripts/grant-ci-gke-iam.sh your-sa@your-project.iam.gserviceaccount.com
#
# Find the email: echo "$GCP_CREDENTIALS_JSON" | jq -r .client_email
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-chennu-platform}"
SA_EMAIL="${1:-}"

if [[ -z "$SA_EMAIL" ]]; then
  echo "Usage: $0 <service-account-email>" >&2
  exit 1
fi

MEMBER="serviceAccount:${SA_EMAIL}"

for ROLE in \
  roles/container.clusterViewer \
  roles/container.developer; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="${MEMBER}" \
    --role="${ROLE}" \
    --condition=None
done

echo "Done. Re-run the failed GitHub Actions workflow."
