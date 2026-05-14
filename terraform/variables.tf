variable "project_id" {
  description = "GCP project ID where all Kickwise resources live."
  type        = string
}

variable "region" {
  description = "Primary GCP region (single-region setup)."
  type        = string
  default     = "europe-west3"
}

variable "region_code" {
  description = "Short region code used in resource naming, e.g. 'euw3'."
  type        = string
  default     = "euw3"
}

variable "app_short" {
  description = "Short app prefix used in resource naming."
  type        = string
  default     = "kickwise"
}

variable "environment" {
  description = "Environment name (currently only 'prod')."
  type        = string
  default     = "prod"
}

variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for all Kickwise data."
  type        = string
  default     = "kickwise_main"
}

variable "playmaker_image" {
  description = "Container image (incl. tag) for the Playmaker Cloud Run service."
  type        = string
  default     = "europe-west3-docker.pkg.dev/kickwise-prod/kickwise/playmaker:latest"
}

variable "winger_image" {
  description = "Container image (incl. tag) for the Winger Cloud Run service."
  type        = string
  default     = "europe-west3-docker.pkg.dev/kickwise-prod/kickwise/winger:latest"
}

variable "scout_image" {
  description = "Container image (incl. tag) for the Scout Cloud Run Job."
  type        = string
  default     = "europe-west3-docker.pkg.dev/kickwise-prod/kickwise/scout:latest"
}

variable "scout_schedule_cron" {
  description = "Cloud Scheduler cron expression for the daily Scout run."
  type        = string
  default     = "0 6 * * *"
}

variable "scout_schedule_timezone" {
  description = "Timezone for the Scout schedule."
  type        = string
  default     = "Europe/Berlin"
}

variable "github_repo_owner" {
  description = "GitHub owner/org used for Workload Identity Federation."
  type        = string
  default     = "juniordev4life"
}

locals {
  resource_prefix = "${var.app_short}-${var.region_code}"

  common_labels = {
    app         = var.app_short
    environment = var.environment
    managed_by  = "terraform"
  }
}
