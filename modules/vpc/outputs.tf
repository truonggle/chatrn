output "vpc_name" {
  description = "The name of the created VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self_link of the VPC (required by GKE module)"
  value       = google_compute_network.vpc.self_link
}

output "gke_subnet_self_link" {
  description = "The self_link of the subnet (required by GKE module)"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "vpc_peering_network" {
  description = "The network ID (not name) to be used for VPC peering (CloudSQL/Filestore)"
  value       = google_compute_network.vpc.id
}

output "pods_ip_range_name" {
  description = "Name of secondary IP range for pods"
  value       = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
}

output "services_ip_range_name" {
  description = "Name of secondary IP range for services"
  value       = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
}