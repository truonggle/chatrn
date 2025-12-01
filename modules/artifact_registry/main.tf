resource "google_project_service" "artifact_registry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "main" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.project_name}-${var.env}-repo"
  description   = var.description
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  depends_on = [google_project_service.artifact_registry_api]
}

# resource "google_artifact_registry_repository_iam_member" "artifact_registry_sa_binding" {
#   project     = var.project_id
#   location    = var.region
#   repository  = google_artifact_registry_repository.main.name
#   role        = var.artifact_registry_custom_role_id
#   member      = "serviceAccount:${var.artifact_registry_sa_email}"
#   depends_on  = [google_artifact_registry_repository.main]
# }

resource "google_artifact_registry_repository_iam_member" "app_workload_sa_binding" {
  project     = var.project_id
  location    = var.region
  repository  = google_artifact_registry_repository.main.name
  role        = var.artifact_registry_custom_role_id
  member      = "serviceAccount:${var.app_workload_sa_email}"
  depends_on  = [google_artifact_registry_repository.main]
}

## Make sure GKE nodes can pull images from a SPECIFIC repository
resource "google_artifact_registry_repository_iam_member" "gke_node_sa_binding" {
  project     = var.project_id
  location    = var.region
  repository  = google_artifact_registry_repository.main.name
  role        = var.artifact_registry_custom_role_id
  member      = "serviceAccount:${var.gke_node_sa_email}"
  depends_on  = [google_artifact_registry_repository.main]
}

# For Cloud Build

data "google_project" "current" {}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_push" {
  project     = var.project_id
  location    = var.region
  repository  = google_artifact_registry_repository.main.id
  role        = "roles/artifactregistry.writer"
  member      = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
  depends_on  = [google_artifact_registry_repository.main]
}