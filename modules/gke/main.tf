resource "google_project_service" "gke_apis" {
  project = var.project_id
  count   = 3
  service = [
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "connectgateway.googleapis.com",
  ][count.index]
  disable_on_destroy = false
}

resource "google_container_cluster" "alpha" {
  name           = "${var.project_name}-${var.env}-alpha-gke"
  project        = var.project_id
  location       = var.region
  node_locations = var.node_zones

  network    = var.vpc_self_link
  subnetwork = var.gke_subnet_self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.gke_master_ipv4_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      # cidr_block    = var.master_authorized_networks_config[0].cidr_block
      # display_name  = var.master_authorized_networks_config[0].display_name
      cidr_block   = "10.0.0.0/8"
      display_name = "RFC1918 - Class A"
    }
    cidr_blocks {
      cidr_block   = "172.16.0.0/12"
      display_name = "RFC1918 - Class B"
    }
    cidr_blocks {
      cidr_block   = "192.168.0.0/16"
      display_name = "RFC1918 - Class C"
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_ip_range_name
    services_secondary_range_name = var.services_ip_range_name
  }

  // enable workload identity on the cluster
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    ray_operator_config {
      enabled = true
      ray_cluster_logging_config {
        enabled = true
      }
      ray_cluster_monitoring_config {
        enabled = true
      }
    }
  }

  logging_service     = "logging.googleapis.com/kubernetes"
  monitoring_service  = "monitoring.googleapis.com/kubernetes"
  deletion_protection = false

  depends_on = [google_project_service.gke_apis]
}

resource "google_gke_hub_membership" "gke_hub" {
  project       = var.project_id
  membership_id = "${var.project_name}-${var.env}-gke-hub"
  location      = "global"

  endpoint {
    gke_cluster {
      resource_link = google_container_cluster.alpha.id
    }
  }

  depends_on = [
    google_container_cluster.alpha,
    google_container_node_pool.cpu_node_pool,
    # google_container_node_pool.gpu_node_pool,
    google_project_service.gke_apis
  ]
}