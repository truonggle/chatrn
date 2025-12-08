output "bucket_name" {
  description = "The globally unique name of the GCS bucket"
  value       = google_storage_bucket.main.name
}

output "bucker_url" {
  description = "The gs:// URL of the bucket"
  value       = google_storage_bucket.main.url
}