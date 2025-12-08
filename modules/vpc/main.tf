resource "google_project_service" "vpc_apis" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.env}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.project_name}-${var.env}-gke-subnet"
  project       = var.project_id
  region        = var.region
  ip_cidr_range = var.gke_subnet_cidr
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods-range"
    ip_cidr_range = var.pods_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = "gke-services-range"
    ip_cidr_range = var.service_ip_cidr_range
  }
}

# Firewall rules

## Allow internal communication : nodes, pods, services talk to each other

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.env}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "10255"]
  }
  allow {
    protocol = "udp"
  }
  allow { protocol = "icmp" }

  source_ranges = [
    var.gke_subnet_cidr,
    var.pods_ip_cidr_range,
    var.service_ip_cidr_range
  ]
  destination_ranges = [
    var.gke_subnet_cidr,
    var.pods_ip_cidr_range,
    var.service_ip_cidr_range
  ]
}

## Allow private GKE master access to nodes

resource "google_compute_firewall" "allow_master_to_nodes" {
  name      = "${var.project_name}-${var.env}-allow-master-to-nodes"
  project   = var.project_id
  network   = google_compute_network.vpc.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }
  allow {
    protocol = "udp"
  }

  source_ranges      = [var.gke_master_ipv4_cidr]
  destination_ranges = [var.gke_subnet_cidr]
}

# Cloud NAT for outbound internet access

resource "google_compute_router" "router" {
  name    = "${var.project_name}-${var.env}-router"
  network = google_compute_network.vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                   = "${var.project_name}-${var.env}-nat"
  router                 = google_compute_router.router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name = google_compute_subnetwork.gke_subnet.id
    source_ip_ranges_to_nat = [
      "PRIMARY_IP_RANGE",
      "gke-pods-range",
      "gke-services-range"
    ]
  }
}

# VPC Peering for private, secure connection (CloudSQL, Filestore) to Google's managed services

## Reserve a private IP range for the connection
resource "google_compute_global_address" "private_service_connect" {
  name          = "${var.project_name}-${var.env}-psc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_connect.name]

  deletion_policy = "ABANDON"

  depends_on = [
    google_project_service.vpc_apis,
    google_compute_global_address.private_service_connect
  ]
}