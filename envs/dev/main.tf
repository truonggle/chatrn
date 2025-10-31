module "iam" {
  source       = "../../modules/iam"
  env          = var.env
  project_id   = var.project_id
  project_name = var.project_name
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
  vpc_self_link        = module.vpc.vpc_self_link
  gke_subnet_self_link = module.vpc.gke_subnet_self_link
}