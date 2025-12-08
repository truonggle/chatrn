module "iam" {
  source       = "../../modules/iam"
  env          = var.env
  project_id   = var.project_id
  project_name = var.project_name
  k8s_namespace = var.k8s_namespace
  k8s_service_account = var.k8s_service_account
  github_username = var.github_username
  github_repository = var.github_repository
}

module "vpc" {
  source                = "../../modules/vpc"
  project_id            = var.project_id
  project_name          = var.project_name
  env                   = var.env
  region                = var.region
  gke_master_ipv4_cidr  = var.gke_master_ipv4_cidr
  gke_subnet_cidr       = var.gke_subnet_cidr
  pods_ip_cidr_range    = var.pods_ip_cidr_range
  service_ip_cidr_range = var.service_ip_cidr_range
}

module "gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  project_name = var.project_name
  region       = var.region
  env          = var.env
  node_zones   = var.node_zones

  gke_master_ipv4_cidr = var.gke_master_ipv4_cidr
  cpu_machine_type     = var.cpu_machine_type
  gpu_machine_type     = var.gpu_machine_type
  gpu_type             = var.gpu_type
  disk_type            = var.disk_type
  image_type           = var.image_type

  gke_node_sa_email    = module.iam.gke_node_sa_email
  app_workload_sa_email = module.iam.app_workload_sa_email
  vpc_self_link        = module.vpc.vpc_self_link
  gke_subnet_self_link = module.vpc.gke_subnet_self_link

  # master_authorized_networks_config = var.master_authorized_networks_config
  pods_ip_range_name = module.vpc.pods_ip_range_name
  services_ip_range_name = module.vpc.services_ip_range_name

  depends_on = [
    module.vpc,
    module.iam
  ]
}

module "artifact_registry" {
  source = "../../modules/artifact_registry"
  project_id = var.project_id
  project_name = var.project_name
  region = var.region
  env = var.env
  description = var.artifact_registry_description
  artifact_registry_custom_role_id = module.iam.artifact_registry_custom_role_id
  artifact_registry_sa_email = module.iam.artifact_registry_sa_email
  app_workload_sa_email = module.iam.app_workload_sa_email
  gke_node_sa_email = module.iam.gke_node_sa_email

  depends_on = [
    module.iam
  ]
}

module "cloudsql" {
  source = "../../modules/cloudsql"
  project_id = var.project_id
  project_name = var.project_name
  region    = var.region
  env    = var.env

  cloudsql_database_tier = var.cloudsql_database_tier
  cloudsql_disk_size = var.cloudsql_disk_size

  vpc_network_id = module.vpc.vpc_peering_network
  gke_service_account_email = module.iam.gke_node_sa_email

  depends_on = [
    module.vpc,
    module.iam
  ]
}

module "secret_manager" {
  source = "../../modules/secret_manager"
  project_id = var.project_id
  project_name = var.project_name
  env = var.env
  secrets = local.all_secrets
  secret_accessors = local.all_secret_accessors

  depends_on = [
    module.cloudsql,
    module.iam
  ]
}

module "cloud_storage" {
  source = "../../modules/cloud_storage"
  project_id = var.project_id
  project_name = var.project_name
  region = var.region
  env    = var.env

  bucket_name_suffix = var.bucket_name_suffix

  app_workload_sa_email = module.iam.app_workload_sa_email
  gcs_custom_role_id = module.iam.gcs_custom_role_id
  gcs_sa_email = module.iam.gcs_sa_email

  depends_on = [
    module.iam
  ]
}