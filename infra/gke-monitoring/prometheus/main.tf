# =============================================================================
# Terraform — Enable Google Managed Prometheus on GKE (scaffolded by Backstage)
# -----------------------------------------------------------------------------
# Purpose:    Enable GMP on an existing GKE cluster; create monitoring namespace.
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "google" {
  project = "chennu-platform"
  region  = "us-central1"
}

# ---------------------------------------------------------------------------
# Data: look up the existing GKE cluster
# ---------------------------------------------------------------------------
data "google_container_cluster" "this" {
  name     = "prometheus"
  location = "us-central1"
  project  = "chennu-platform"
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

# ---------------------------------------------------------------------------
# Enable Google Managed Prometheus on the GKE cluster
# ---------------------------------------------------------------------------
resource "google_container_cluster" "monitoring_update" {
  name     = data.google_container_cluster.this.name
  location = data.google_container_cluster.this.location
  project  = "chennu-platform"

  # Preserve existing config — only update monitoring
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = true
    }
  }

  # Prevent Terraform from trying to recreate the cluster
  lifecycle {
    ignore_changes = [
      node_config,
      node_pool,
      initial_node_count,
      network,
      subnetwork,
      resource_labels,
    ]
  }
}

# ---------------------------------------------------------------------------
# Create monitoring namespace
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "backstage"
      "purpose"                      = "prometheus-monitoring"
    }
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "cluster_name" {
  value = data.google_container_cluster.this.name
}

output "monitoring_namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "gmp_enabled" {
  value = true
}
