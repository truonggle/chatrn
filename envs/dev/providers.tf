provider "google" {
  project = var.project_id
  region  = var.region
}

# provider "helm" {
#   kubernetes {
    # host                   = "https://${module.gke.cluster_endpoint}"
    # host = "https://connectgateway.googleapis.com/v1/projects/${data.google_client_config.default.project}/locations/global/gkeMemberships/${module.gke.membership_id}"
    # token                  = data.google_client_config.default.access_token
    # cluster_ca_certificate = ""
    # cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  # }
# }

# data "google_client_config" "default" {}
#
# provider "kubernetes" {
#   # host = "https://${module.gke.cluster_endpoint}"
#   host = "https://connectgateway.googleapis.com/v1/projects/${data.google_client_config.default.project}/locations/global/gkeMemberships/${module.gke.membership_id}"
#   token = data.google_client_config.default.access_token
#   cluster_ca_certificate = ""
#   # cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
# }