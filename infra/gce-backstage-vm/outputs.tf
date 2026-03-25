# =============================================================================
# Outputs — Backstage VM
# =============================================================================

output "instance_name" {
  value = google_compute_instance.backstage.name
}

output "instance_zone" {
  value = google_compute_instance.backstage.zone
}

output "external_ip" {
  value = google_compute_instance.backstage.network_interface[0].access_config[0].nat_ip
}

output "backstage_url" {
  value = "http://${google_compute_instance.backstage.network_interface[0].access_config[0].nat_ip}:7007"
}

