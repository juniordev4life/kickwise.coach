output "playmaker_service_url" {
  description = "Direct Cloud Run URL of the Playmaker service."
  value       = module.cloud_run.playmaker_service_url
}

output "winger_service_url" {
  description = "Direct Cloud Run URL of the Winger service."
  value       = module.cloud_run.winger_service_url
}

output "striker_bucket_name" {
  description = "Cloud Storage bucket hosting the Striker static files."
  value       = module.storage.striker_bucket_name
}

output "load_balancer_ip" {
  description = "Public IP of the global HTTPS load balancer."
  value       = module.load_balancer.load_balancer_ip
}

output "bigquery_dataset_id" {
  description = "Fully qualified BigQuery dataset for Kickwise data."
  value       = module.bigquery.dataset_id
}

output "workload_identity_provider" {
  description = "Workload Identity Provider resource name for GitHub Actions OIDC."
  value       = module.workload_identity.provider_name
}
