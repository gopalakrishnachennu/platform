# =============================================================================
# Terraform — GCS bucket (scaffolded by Backstage template)
# -----------------------------------------------------------------------------
# Purpose:    Create one google_storage_bucket; output bucket_name for CI/GitOps.
# State:      GCS backend (prefix = directory path); CI sets bucket in workflow.
# Values:     Injected by Backstage fetch:template (cookiecutter-style placeholders).
# =============================================================================
terraform {
  required_version = ">= 1.4.0"
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "${{ values.gcpProjectId }}"
  region  = "${{ values.gcpRegion }}"
}

resource "google_storage_bucket" "this" {
  name                        = "${{ values.bucketName }}"
  location                    = "${{ values.gcpRegion }}"
  uniform_bucket_level_access = true
  versioning {
{% if values.enableVersioning %}
    enabled = true
{% else %}
    enabled = false
{% endif %}
  }
{% if values.forceDestroy %}
  force_destroy               = true
{% else %}
  force_destroy               = false
{% endif %}
}

output "bucket_name" {
  value = google_storage_bucket.this.name
}
