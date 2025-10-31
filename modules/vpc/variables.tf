variable "project_id" { type = string }
variable "project_name" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "gke_master_ipv4_cidr" { type = string }
variable "gke_subnet_cidr" { type = string }
variable "pods_ip_cidr_range" { type = string }
variable "service_ip_cidr_range" { type = string }