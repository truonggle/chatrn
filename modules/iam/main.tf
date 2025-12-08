## GKE Node SA (minimal permissions, for Node VMs)
## We won't use the default Compute Engine SA
resource "google_service_account" "gke_node_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-${var.env}-gke-node-sa"
  display_name = "GKE Node VM SA (minimal)"
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  count   = 2
  project = var.project_id
  role = [
    "roles/logging.logWriter",       # To write logs to Cloud Logging
    "roles/monitoring.metricWriter", # To write metrics to Cloud Monitoring
    # "roles/artifactregistry.reader",    # delegate to custom role (less permissions)
  ][count.index]
  member = "serviceAccount:${google_service_account.gke_node_sa.email}"

  depends_on = [google_service_account.gke_node_sa]
}

## Application Workload SA (for Pods)
resource "google_service_account" "app_workload_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-${var.env}-app-workload-sa"
  display_name = "Application Pod SA (for Cloud SQL, GCS)"
}

resource "google_project_iam_member" "app_workload_sa_roles" {
  count   = 2
  project = var.project_id
  role = [
    # "roles/cloudsql.client", # To connect to Cloud SQL (too many permissions)
    # "roles/storage.objectUser" # To read/write to GCS buckets (too many permissions)
    google_project_iam_custom_role.artifact_registry_reader_role.name,
    google_project_iam_custom_role.gcs_rw_role.name,
  ][count.index]
  member = "serviceAccount:${google_service_account.app_workload_sa.email}"
  depends_on = [
    google_service_account.app_workload_sa,
    google_project_iam_custom_role.artifact_registry_reader_role,
    google_project_iam_custom_role.gcs_rw_role,
  ]
}

## Dummy SA with no pull permission , no GCS access
resource "google_service_account" "dummy_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-${var.env}-dummy-sa"
  display_name = "Dummy SA"
}

resource "google_project_iam_member" "dummy_sa_roles" {
  project    = var.project_id
  role       = "roles/viewer"
  member     = "serviceAccount:${google_service_account.dummy_sa.email}"
  depends_on = [google_service_account.dummy_sa]
}

## Minimal, custom SA for Artifact Registry read access
resource "google_service_account" "artifact_registry_sa" {
  project      = var.project_id
  display_name = "Artifact Registry Reader"
  account_id   = "artifact-registry-reader"
}

resource "google_project_iam_custom_role" "artifact_registry_reader_role" {
  role_id     = "artifactRegistryImagePuller"
  title       = "Artifact Registry Image Puller"
  description = "Can only read container images from Artifact Registry"
  permissions = [
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.downloadArtifacts",
  ]
  stage = "GA"
}

## Minimal, custom SA for GCS access (read/write)
resource "google_service_account" "gcs_sa" {
  project      = var.project_id
  display_name = "Cloud Storage Accessor"
  account_id   = "gcs-accessor"
}

resource "google_project_iam_custom_role" "gcs_rw_role" {
  role_id     = "gcsObjectReadWrite"
  title       = "GCS Object Read Write"
  description = "Can read and write objects in Cloud Storage (no bucket-level admin)"
  permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.delete",
  ]
  stage = "GA"
}

## Workload Identity Bindings

resource "google_service_account_iam_binding" "app_workload_sa_binding" {
  service_account_id = google_service_account.app_workload_sa.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
  ]
  depends_on = [google_service_account.app_workload_sa]
}

resource "google_service_account_iam_binding" "dummy_sa_binding" {
  service_account_id = google_service_account.dummy_sa.id
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/app-workload-sa-dummy]"
  ]
  depends_on = [google_service_account.dummy_sa]
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
  description               = "Workload Identity Pool for GitHub Actions"
}

# OIDC Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository_owner == '${var.github_username}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions SA"
  description  = "Service account for GitHub Actions"
}

# IAM Binding to allow GitHub Actions to impersonate the SA
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/cloudbuild.builds.editor",
    "roles/logging.viewer",
    "roles/gkehub.viewer",
    "roles/gkehub.gatewayReader",
    "roles/gkehub.gatewayEditor",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Workload Identity User Binding
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_username}/${var.github_repository}"
}