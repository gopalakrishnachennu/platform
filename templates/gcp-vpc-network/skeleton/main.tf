# =============================================================================
# Terraform — VPC + subnet + firewall (scaffolded by Backstage template)
# -----------------------------------------------------------------------------
# Purpose:    Create VPC network, subnet, and baseline firewall rules in GCP.
# Outputs:    vpc_name, subnet_name — consumed by infra-terraform.yml for Argo info.
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

resource "google_compute_network" "vpc" {
  name                    = "${{ values.networkName }}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${{ values.subnetName }}"
  ip_cidr_range = "${{ values.subnetCidr }}"
  region        = "${{ values.gcpRegion }}"
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${google_compute_network.vpc.name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${{ values.sourceCidr }}"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${google_compute_network.vpc.name}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["${{ values.sourceCidr }}"]
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}
