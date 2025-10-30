output "gke_node_sa_email" {
  description = "The email of the minimal SA for GKE nodes"
  value = google_service_account.gke_node_sa.email
}