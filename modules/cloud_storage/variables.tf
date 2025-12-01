variable "project_id" { type = string }
variable "project_name" { type = string }
variable "region" { type = string }
variable "env" { type = string }
variable "bucket_name_suffix" {
  type = string
  default = "data-bucket"
}
variable "app_workload_sa_email" { type = string }
variable "gcs_custom_role_id" { type = string}
variable "gcs_sa_email" { type = string }