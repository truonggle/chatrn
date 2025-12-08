resource "google_project_service" "cloudsql_apis" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-${var.env}-db-${random_id.db_suffix.hex}"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  deletion_protection = false

  settings {
    tier                  = var.cloudsql_database_tier
    availability_type     = "REGIONAL"
    disk_type             = "PD_SSD"
    disk_size             = var.cloudsql_disk_size
    disk_autoresize       = true
    disk_autoresize_limit = 100

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_network_id
      enable_private_path_for_google_cloud_services = true
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "On"
    }
  }

  depends_on = [google_project_service.cloudsql_apis]
}

resource "google_sql_database" "database" {
  name     = "${var.project_name}_${var.env}_db"
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "app_user" {
  name     = "${var.project_name}-${var.env}-app-user"
  instance = google_sql_database_instance.main.name
  project  = var.project_id
  password = random_password.db_password.result
}

resource "google_sql_user" "app_workload_identity_user" {
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  name     = trimsuffix(var.gke_service_account_email, ".gserviceaccount.com")
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}