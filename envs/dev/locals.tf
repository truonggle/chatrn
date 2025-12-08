locals {
  all_secrets = merge(
    var.secrets,
    {
      db-password = module.cloudsql.db_password
      db-host     = module.cloudsql.private_ip_address
      db-name     = module.cloudsql.database_name
      db-user     = module.cloudsql.db_user
      workload-identity-provider = module.iam.workload_identity_provider
    }
  )

  all_secret_accessors = {
    gke_db_password = {
      secret_name = "db-password"
      member      = "serviceAccount:${module.iam.gke_node_sa_email}"
    }
    gke_db_host = {
      secret_name = "db-host"
      member      = "serviceAccount:${module.iam.gke_node_sa_email}"
    }
    gke_db_name = {
      secret_name = "db-name"
      member      = "serviceAccount:${module.iam.gke_node_sa_email}"
    }
    gke_db_user = {
      secret_name = "db-user"
      member      = "serviceAccount:${module.iam.gke_node_sa_email}"
    }
    workload_identity_provider_accessor = {
      secret_name = "workload-identity-provider"
      member      = "serviceAccount:${module.iam.github_actions_sa_email}"
    }
  }
}