variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "scout_job_name" {
  type = string
}

variable "scheduler_sa_email" {
  type = string
}

variable "scout_schedule_cron" {
  type = string
}

variable "scout_schedule_tz" {
  type = string
}

resource "google_project_iam_member" "scheduler_can_invoke_jobs" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${var.scheduler_sa_email}"
}

resource "google_cloud_scheduler_job" "scout_daily" {
  name        = "${var.resource_prefix}-sched-scout-daily"
  project     = var.project_id
  region      = var.region
  description = "Triggers the Scout Cloud Run Job daily for the current Bundesliga season."
  schedule    = var.scout_schedule_cron
  time_zone   = var.scout_schedule_tz

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.scout_job_name}:run"

    oauth_token {
      service_account_email = var.scheduler_sa_email
    }
  }

  retry_config {
    retry_count = 2
  }
}
