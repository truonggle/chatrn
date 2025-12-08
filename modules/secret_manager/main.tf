resource "google_project_service" "secretmanager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "secrets" {
  # for_each = var.secrets
  for_each = nonsensitive(toset(keys(var.secrets)))

  secret_id = "${var.project_name}-${var.env}-${each.key}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.env
    managed_by  = "terraform"
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  secret = google_secret_manager_secret.secrets[each.key].id
  # secret_data = each.value
  secret_data = var.secrets[each.key]
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = var.secret_accessors

  secret_id = google_secret_manager_secret.secrets[each.value.secret_name].id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}