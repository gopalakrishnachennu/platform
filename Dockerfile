# =============================================================================
# IMAGE: platform-api
# -----------------------------------------------------------------------------
# Purpose:    Minimal runtime for the GitOps demo app — serves static files from app/
#             via Python's built-in HTTP server on port 8080.
# Build:      Cloud Build (see .github/workflows/ci-cloudbuild.yml) pushes to
#             Artifact Registry; Argo CD deploys the tagged image from gitops/.
# =============================================================================

FROM python:3.12-alpine

WORKDIR /app
COPY app/ /app/

EXPOSE 8080

CMD ["python", "-m", "http.server", "8080"]
