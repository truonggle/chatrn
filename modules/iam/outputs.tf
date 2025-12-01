output "gke_node_sa_email" {
  description = "The email of the minimal SA for GKE nodes"
  value = google_service_account.gke_node_sa.email
}

output "app_workload_sa_email" {
  description = "The email of the SA for application workloads"
  value = google_service_account.app_workload_sa.email
}

output "app_workload_sa_id" {
  value = google_service_account.app_workload_sa.id
}

output "dummy_sa_id" {
  value = google_service_account.dummy_sa.id
}

output "gcs_custom_role_id" {
  value = google_project_iam_custom_role.gcs_rw_role.id
}

output "gcs_sa_email" {
  value = google_service_account.gcs_sa.email
}

output "artifact_registry_custom_role_id" {
  value = google_project_iam_custom_role.artifact_registry_reader_role.id
}

output "artifact_registry_sa_email" {
  value = google_service_account.artifact_registry_sa.email
}