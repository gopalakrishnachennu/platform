# =============================================================================
# Terraform — Google Managed Prometheus on existing GKE (platform-lab)
# -----------------------------------------------------------------------------
# CI:         infra-terraform.yml — prefix infra/gke-monitoring/prometheus
# Cluster:    Must match .github/workflows/infra-terraform.yml (GKE_CLUSTER / GKE_ZONE).
# IAM:        See workflow header — GCP_CREDENTIALS SA needs GKE read + cluster update
#             + ability to create namespaces via Kubernetes API.
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

# Zonal cluster: location MUST be the zone (not the region alone).
data "google_container_cluster" "this" {
  name     = "platform-lab"
  location = "us-central1-a"
  project  = "chennu-platform"
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

resource "google_container_cluster" "monitoring_update" {
  name     = data.google_container_cluster.this.name
  location = data.google_container_cluster.this.location
  project  = "chennu-platform"

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = true
    }
  }

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

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "purpose"                      = "prometheus-monitoring"
    }
  }
}

output "cluster_name" {
  value = data.google_container_cluster.this.name
}

output "monitoring_namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "gmp_enabled" {
  value = true
}
