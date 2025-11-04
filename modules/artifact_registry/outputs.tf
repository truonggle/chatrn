output "repository_url" {
  description = "The full URL of the Docker repository"
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "repository_id" {
  description = "The ID of the repository"
  value = google_artifact_registry_repository.main.repository_id
}