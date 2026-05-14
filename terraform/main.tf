provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "service_accounts" {
  source = "./modules/service_accounts"

  project_id      = var.project_id
  resource_prefix = local.resource_prefix
}

module "secrets" {
  source = "./modules/secrets"

  project_id         = var.project_id
  resource_prefix    = local.resource_prefix
  playmaker_sa_email = module.service_accounts.playmaker_sa_email
  winger_sa_email    = module.service_accounts.winger_sa_email
  labels             = local.common_labels
}

module "firestore" {
  source = "./modules/firestore"

  project_id = var.project_id
  region     = var.region
}

module "bigquery" {
  source = "./modules/bigquery"

  project_id         = var.project_id
  region             = var.region
  dataset_id         = var.bigquery_dataset_id
  resource_prefix    = local.resource_prefix
  playmaker_sa_email = module.service_accounts.playmaker_sa_email
  scout_sa_email     = module.service_accounts.scout_sa_email
  engine_sa_email    = module.service_accounts.engine_sa_email
  labels             = local.common_labels
}

module "storage" {
  source = "./modules/storage"

  project_id      = var.project_id
  region          = var.region
  resource_prefix = local.resource_prefix
  labels          = local.common_labels
}

module "cloud_run" {
  source = "./modules/cloud_run"

  project_id         = var.project_id
  region             = var.region
  resource_prefix    = local.resource_prefix
  playmaker_image    = var.playmaker_image
  winger_image       = var.winger_image
  playmaker_sa_email = module.service_accounts.playmaker_sa_email
  winger_sa_email    = module.service_accounts.winger_sa_email
  jwt_secret_id      = module.secrets.jwt_secret_id
  labels             = local.common_labels

  depends_on = [module.firestore, module.bigquery]
}

module "cloud_run_job" {
  source = "./modules/cloud_run_job"

  project_id      = var.project_id
  region          = var.region
  resource_prefix = local.resource_prefix
  scout_image     = var.scout_image
  scout_sa_email  = module.service_accounts.scout_sa_email
  dataset_id      = var.bigquery_dataset_id
  labels          = local.common_labels

  depends_on = [module.bigquery]
}

module "cloud_scheduler" {
  source = "./modules/cloud_scheduler"

  project_id          = var.project_id
  region              = var.region
  resource_prefix     = local.resource_prefix
  scout_job_name      = module.cloud_run_job.scout_job_name
  scheduler_sa_email  = module.service_accounts.scheduler_sa_email
  scout_schedule_cron = var.scout_schedule_cron
  scout_schedule_tz   = var.scout_schedule_timezone

  depends_on = [module.cloud_run_job]
}

# Phase-1: HTTPS Load Balancer ist bewusst auskommentiert, um den Fixpreis
# (~18 €/Monat für die globale IP) zu sparen. Wir greifen direkt auf die
# default *.run.app-URLs und die Cloud-Storage-Public-URL des Striker-Buckets
# zurück. Sobald wir eine Custom-Domain anhängen wollen, wird dieses Modul
# wieder aktiviert.
#
# module "load_balancer" {
#   source = "./modules/load_balancer"
#
#   project_id             = var.project_id
#   region                 = var.region
#   resource_prefix        = local.resource_prefix
#   striker_bucket_name    = module.storage.striker_bucket_name
#   playmaker_service_name = module.cloud_run.playmaker_service_name
#   labels                 = local.common_labels
#
#   depends_on = [module.cloud_run, module.storage]
# }

module "workload_identity" {
  source = "./modules/workload_identity"

  project_id        = var.project_id
  resource_prefix   = local.resource_prefix
  github_repo_owner = var.github_repo_owner
}

module "artifact_registry" {
  source = "./modules/artifact_registry"

  project_id             = var.project_id
  region                 = var.region
  resource_prefix        = local.resource_prefix
  playmaker_sa_email     = module.service_accounts.playmaker_sa_email
  winger_sa_email        = module.service_accounts.winger_sa_email
  scout_sa_email         = module.service_accounts.scout_sa_email
  engine_sa_email        = module.service_accounts.engine_sa_email
  github_deploy_sa_email = module.workload_identity.github_deploy_sa_email
  labels                 = local.common_labels
}
