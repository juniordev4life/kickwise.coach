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

output "artifact_registry_url" {
  description = "Base URL for Kickwise container images, e.g. europe-west3-docker.pkg.dev/kickwise-prod/kickwise."
  value       = module.artifact_registry.repository_url
}

output "github_deploy_sa_email" {
  description = "Service account used by GitHub Actions to push images and deploy."
  value       = module.workload_identity.github_deploy_sa_email
}
