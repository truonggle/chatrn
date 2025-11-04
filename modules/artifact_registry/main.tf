resource "google_project_service" "artifact_registry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "main" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.project_name}-${var.env}-repo"
  description = var.description
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  depends_on = [google_project_service.artifact_registry_api]
}