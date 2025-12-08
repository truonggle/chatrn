output "instance_name" {
  description = "The name of the CloudSQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the CloudSQL instance (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.main.connection_name
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.database.name
}

output "private_ip_address" {
  description = "The private IP address of the CloudSQL instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "db_user" {
  description = "Database user name"
  value       = google_sql_user.app_user.name
}

output "db_password" {
  description = "Database user password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}