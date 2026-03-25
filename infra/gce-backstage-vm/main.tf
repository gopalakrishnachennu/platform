# =============================================================================
# Terraform — Backstage on Compute Engine (VM)
# -----------------------------------------------------------------------------
# Goal:   Provision a GCE VM and run Backstage on port 7007 via Docker.
# CI:     .github/workflows/infra-terraform.yml will plan/apply this directory.
# Notes:  - This is a simple VM-based deployment (no HTTPS, no DB) intended for demos.
#         - For production, run Backstage on GKE with TLS + Postgres + secret manager.
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
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  vm_name = var.instance_name

  startup_script = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker

    # Ensure the container is always running
    docker rm -f backstage >/dev/null 2>&1 || true
    docker pull ${var.backstage_image}
    docker run -d --restart=always --name backstage -p 7007:7007 ${var.backstage_image}
  EOT
}

resource "google_compute_firewall" "allow_backstage_7007" {
  name    = "${local.vm_name}-allow-7007"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["7007"]
  }

  source_ranges = var.source_ranges
  target_tags   = ["backstage"]
}

resource "google_compute_instance" "backstage" {
  name         = local.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["backstage"]

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = var.network

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    startup-script = local.startup_script
  }

  service_account {
    email  = var.instance_service_account_email != "" ? var.instance_service_account_email : null
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

