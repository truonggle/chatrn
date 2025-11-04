variable "project_id" { type = string }
variable "project_name" { type = string }
variable "region" { type = string }
variable "env" { type = string }
variable "vpc_network_id" { type = string }
variable "cloudsql_database_tier" { type = string }
variable "cloudsql_disk_size" { type = number }
variable "gke_service_account_email" { type = string }