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
  name                        = "sai-99"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  force_destroy = false
}

output "bucket_name" {
  value = google_storage_bucket.this.name
}
