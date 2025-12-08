resource "google_container_node_pool" "cpu_node_pool" {
  project            = var.project_id
  name               = "${var.project_name}-${var.env}-cpu-pool"
  location           = var.region
  cluster            = google_container_cluster.alpha.name
  node_locations     = var.node_zones
  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  node_config {
    machine_type = var.cpu_machine_type
    disk_type    = var.disk_type
    disk_size_gb = 50
    image_type   = var.image_type

    // For custom sa, gke nodes authenticate using sa credentials, not OAuth scopes.
    service_account = var.gke_node_sa_email
    oauth_scopes    = []
  }
}

# resource "google_container_node_pool" "gpu_node_pool" {
#   project         = var.project_id
#   name            = "${var.project_name}-${var.env}-gpu-pool"
#   location        = var.region
#   cluster         = google_container_cluster.alpha.name
#   node_locations  = var.node_zones
#   initial_node_count = 1
#
#   autoscaling {
#     min_node_count = 0
#     max_node_count = 1
#   }
#
#   node_config {
#     machine_type    = var.gpu_machine_type
#     disk_type       = var.disk_type
#     disk_size_gb    = 100
#     image_type      = var.image_type
#
#     service_account = var.gke_node_sa_email
#     oauth_scopes    = []
#
#     guest_accelerator {
#       count = 1
#       type  = var.gpu_type
#       gpu_driver_installation_config {
#         gpu_driver_version = "DEFAULT"
#       }
#     }
#   }
# }