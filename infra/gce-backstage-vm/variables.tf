# =============================================================================
# Variables — Backstage VM
# =============================================================================

variable "project_id" {
  type        = string
  description = "GCP project ID."
  default     = "chennu-platform"
}

variable "region" {
  type        = string
  description = "GCP region."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone (VM will be created here)."
  default     = "us-central1-a"
}

variable "network" {
  type        = string
  description = "VPC network name."
  default     = "default"
}

variable "instance_name" {
  type        = string
  description = "Compute Engine instance name."
  default     = "backstage-vm"
}

variable "machine_type" {
  type        = string
  description = "Compute Engine machine type."
  default     = "e2-medium"
}

variable "boot_image" {
  type        = string
  description = "Boot disk image (Ubuntu LTS)."
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_gb" {
  type        = number
  description = "Boot disk size in GB."
  default     = 50
}

variable "backstage_image" {
  type        = string
  description = "Backstage container image."
  default     = "ghcr.io/backstage/backstage:latest"
}

variable "source_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access Backstage on port 7007."
  default     = ["0.0.0.0/0"]
}

variable "instance_service_account_email" {
  type        = string
  description = "Service account email for the VM. Empty uses the project's default Compute Engine service account."
  default     = ""
}

