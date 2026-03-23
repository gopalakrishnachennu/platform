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
  project = "chennu-platform"
  region  = "us-central1"
}

resource "google_storage_bucket" "this" {
  name                        = "midh-9898989"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  versioning {

    enabled = true

  }

  force_destroy               = false

}

output "bucket_name" {
  value = google_storage_bucket.this.name
}
