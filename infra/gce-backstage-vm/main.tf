# =============================================================================
# Terraform — Backstage on Compute Engine (VM)
# -----------------------------------------------------------------------------
# Goal:   Provision a GCE VM and run Backstage on port 7007 (no Docker).
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
    apt-get install -y curl ca-certificates git python3 build-essential gnupg

    # Node.js 20 + Corepack (Yarn)
    install -d /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
    apt-get update -y
    apt-get install -y nodejs
    corepack enable

    APP_DIR=/opt/backstage
    if [ ! -d "$${APP_DIR}" ]; then
      cd /opt
      npx --yes @backstage/create-app@latest --path backstage --skip-install
      cd "$${APP_DIR}"
      yarn install --immutable || yarn install
      yarn build:backend
    fi

    cat >/etc/systemd/system/backstage.service <<'UNIT'
    [Unit]
    Description=Backstage (Node)
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    WorkingDirectory=/opt/backstage
    Environment=NODE_ENV=production
    ExecStart=/usr/bin/yarn start --config app-config.yaml --config app-config.production.yaml
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now backstage
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

