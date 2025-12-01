output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.alpha.name
}

output "cluster_endpoint" {
  description = "The private endpoint of the GKE cluster master"
  value       = google_container_cluster.alpha.endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster's root CA certificate (base64 encoded)"
  value       = google_container_cluster.alpha.master_auth[0].cluster_ca_certificate
}

output "gke_hub_membership_name" {
  description = "The full resource name of the GKE Hub membership"
  value       = google_gke_hub_membership.gke_hub.name
}

output "membership_id" {
  description = "The membership ID of the GKE Hub membership"
  value       = google_gke_hub_membership.gke_hub.membership_id
}