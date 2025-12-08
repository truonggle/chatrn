resource "google_project_service" "storage_api" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "main" {
  project  = var.project_id
  name     = "${var.project_name}-${var.env}-${var.bucket_name_suffix}"
  location = var.region

  uniform_bucket_level_access = true

  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  force_destroy = true

  depends_on = [google_project_service.storage_api]
}

# resource "google_storage_bucket_iam_member" "gcs_sa_binding" {
#   bucket = google_storage_bucket.main.name
#   role   = var.gcs_custom_role_id
#   member = "serviceAccount:${var.gcs_sa_email}"
#   depends_on = [google_storage_bucket.main]
# }

resource "google_storage_bucket_iam_member" "app_workload_sa_bucket_binding" {
  bucket = google_storage_bucket.main.name
  # role   = "roles/storage.objectAdmin"
  role       = var.gcs_custom_role_id
  member     = "serviceAccount:${var.app_workload_sa_email}"
  depends_on = [google_storage_bucket.main]
}