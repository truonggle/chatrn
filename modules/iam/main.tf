## GKE Node SA (minimal permissions, for Node VMs)
resource "google_service_account" "gke_node_sa" {
  project = var.project_id
  account_id = "${var.project_name}-${var.env}-gke-node-sa"
  display_name = "GKE Node VM SA (minimal)"
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  count = 3
  project = var.project_id
  role = [
    "roles/logging.logWriter", # To write logs to Cloud Logging
    "roles/monitoring.metricWriter", # To write metrics to Cloud Monitoring
    "roles/artifactregistry.reader"
  ][count.index]
  member = google_service_account.gke_node_sa.member

  depends_on = [google_service_account.gke_node_sa]
}

## Application Workload SA (for Pods)
resource "google_service_account" "app_workload_sa" {
  project = var.project_id
  account_id = "${var.project_name}-${var.env}-app-workload-sa"
  display_name = "Application Pod SA (for Cloud SQL, GCS)"
}

resource "google_project_iam_member" "app_workload_sa_roles" {
  count = 2
  project = var.project_id
  role    = [
    "roles/cloudsql.client", # To connect to Cloud SQL
    "roles/storage.objectUser" # To read/write to GCS buckets
  ][count.index]
  member  = google_service_account.app_workload_sa.member

  depends_on = [google_service_account.app_workload_sa]
}

# resource "google_service_account_iam_binding" "workload_identity_binding" {
#   service_account_id = google_service_account.app_workload_sa.name
#   role               = "roles/iam.workloadIdentityUser"
#   members = [
#     "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
#   ]
# }