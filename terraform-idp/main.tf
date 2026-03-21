terraform {
  required_version = ">= 1.4.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.28"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "team_namespace" {
  description = "Namespace for the team"
  type        = string
  default     = "team-a"
}

variable "service_account_name" {
  description = "Service account name for team access"
  type        = string
  default     = "team-viewer"
}

resource "kubernetes_namespace" "team" {
  metadata {
    name = var.team_namespace
    labels = {
      managed-by = "terraform"
      project    = "idp"
    }
  }
}

resource "kubernetes_resource_quota" "team_quota" {
  metadata {
    name      = "team-quota"
    namespace = kubernetes_namespace.team.metadata[0].name
  }

  spec {
    hard = {
      "limits.cpu"    = "4"
      "limits.memory" = "8Gi"
      "pods"          = "20"
    }
  }
}

resource "kubernetes_limit_range" "team_limits" {
  metadata {
    name      = "default-container-limits"
    namespace = kubernetes_namespace.team.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "250m"
        memory = "256Mi"
      }
    }
  }
}

resource "kubernetes_service_account" "team_sa" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.team.metadata[0].name
  }
}

resource "kubernetes_role" "team_view_role" {
  metadata {
    name      = "team-namespace-view"
    namespace = kubernetes_namespace.team.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "team_view_binding" {
  metadata {
    name      = "team-namespace-view-binding"
    namespace = kubernetes_namespace.team.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.team_view_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.team_sa.metadata[0].name
    namespace = kubernetes_namespace.team.metadata[0].name
  }
}

output "team_namespace" {
  value = kubernetes_namespace.team.metadata[0].name
}

output "service_account" {
  value = kubernetes_service_account.team_sa.metadata[0].name
}
