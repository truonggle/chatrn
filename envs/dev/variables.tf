variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region for resources"
  type        = string
}

variable "node_zones" {
  description = "List of zones for GKE node pools"
  type        = list(string)
}

variable "project_name" {
  description = "GCP Project Name"
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "gke_master_ipv4_cidr" {
  description = "A dedicated /28 IP range for the GKE private master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_subnet_cidr" {
  description = "Primary range for the GKE subnet (where the Node VMs will get their IPs)"
  type        = string
  default     = "10.10.0.0/16"
}

# variable "master_authorized_networks_config" {
#   description = "List of CIDR blocks allowed to access the GKE master endpoint"
#   type = list(object({
#     cidr_block   = string
#     display_name = string
#   }))
# }

variable "pods_ip_cidr_range" {
  description = "Secondary range for the GKE pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "service_ip_cidr_range" {
  description = "Secondary range for the GKE services"
  type        = string
  default     = "10.30.0.0/20"
}

# --- Node Pools ---

variable "cpu_machine_type" {
  description = "Machine type for the primary CPU node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "gpu_machine_type" {
  description = "Machine type for the GPU pool (must support the GPU type)"
  type        = string
  default     = "n1-standard-4"
}

variable "gpu_type" {
  description = "The type of GPU to attach (e.g., 'nvidia-tesla-t4')"
  type        = string
  default     = "nvidia-tesla-t4"
}

variable "disk_type" {
  description = "Type of disk to use for instances"
  type        = string
  default     = "pd-standard"
}

variable "image_type" {
  description = "The image type for the GKE nodes"
  type        = string
  default     = "COS_CONTAINERD"
}

# --- Artifact Registry ---

variable "artifact_registry_description" {
  description = "Description for the Artifact Registry repository"
  type        = string
  default     = "Docker repository for dev environment"
}

# --- CloudSQL ---

variable "cloudsql_database_tier" {
  description = "The machine type for CloudSQL instance"
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_disk_size" {
  description = "Disk size in GB for CloudSQL instance"
  type        = number
  default     = 10
}

# --- Secret Manager ---

variable "secrets" {
  description = "Map of secret names to secret values"
  type        = map(string)
  sensitive   = true
  default     = {
    db-password = "dev_db_password"
  }
}

# --- Cloud Storage ---

variable "bucket_name_suffix" {
  description = "Suffix for the main data GCS bucket"
  type        = string
  default     = "data-bucket"
}

# --- Kubernetes ---

variable "k8s_service_account" {
  description = "Kubernetes service account name for application workloads"
  type        = string
  default     = "app-workload-sa"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for application workloads"
  type        = string
  default     = "default"
}