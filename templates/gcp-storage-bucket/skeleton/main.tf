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
  project = "{{ values.gcpProjectId }}"
  region  = "{{ values.gcpRegion }}"
}

resource "google_storage_bucket" "this" {
  name                        = "{{ values.bucketName }}"
  location                    = "{{ values.gcpRegion }}"
  uniform_bucket_level_access = true
{% if values.forceDestroy %}
  force_destroy               = true
{% else %}
  force_destroy               = false
{% endif %}
}

resource "google_storage_bucket_versioning" "this" {
  bucket = google_storage_bucket.this.name
  versioning {
{% if values.enableVersioning %}
    enabled = true
{% else %}
    enabled = false
{% endif %}
  }
}

output "bucket_name" {
  value = google_storage_bucket.this.name
}
