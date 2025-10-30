terraform {
  backend "gcs" {
    bucket = "dev-ops-0"
    prefix = "terraform/state"
  }
}