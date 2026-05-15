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

variable "player_snapshot_cron" {
  type    = string
  default = "30 1 * * *"
}

variable "player_snapshot_tz" {
  type    = string
  default = "Europe/Berlin"
}

variable "scout_sa_email" {
  type        = string
  description = "Scout runtime SA — needed for serviceAccountUser on the scheduler."
  default     = ""
}

variable "engine_service_url" {
  type        = string
  description = "Engine Cloud Run URL — used to POST /predictions/refresh-current."
  default     = ""
}

variable "engine_refresh_cron" {
  type    = string
  default = "0 7 * * *"
}

variable "engine_refresh_tz" {
  type    = string
  default = "Europe/Berlin"
}

# Cloud Run v2 Jobs:run requires run.jobs.run which `roles/run.invoker`
# (services-only) does not include — use roles/run.developer.
resource "google_project_iam_member" "scheduler_can_invoke_jobs" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${var.scheduler_sa_email}"
}

# Scheduler also needs to act as the Scout runtime SA to launch the job.
resource "google_service_account_iam_member" "scheduler_acts_as_scout" {
  count              = var.scout_sa_email != "" ? 1 : 0
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.scout_sa_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.scheduler_sa_email}"
}

# Daily openligadb sync (matches, teams, seasons). Default 06:00 Berlin.
resource "google_cloud_scheduler_job" "scout_daily" {
  name        = "${var.resource_prefix}-sched-scout-daily"
  project     = var.project_id
  region      = var.region
  description = "Triggers the Scout Cloud Run Job daily for the current Bundesliga season."
  schedule    = var.scout_schedule_cron
  time_zone   = var.scout_schedule_tz

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${var.scout_job_name}:run"

    oauth_token {
      service_account_email = var.scheduler_sa_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  retry_config {
    retry_count = 2
  }
}

# Nightly Kickbase player snapshot (player profiles + market values). 01:30
# Berlin to land after all evening matches and Kickbase's 22:xx market-value
# update window.
resource "google_cloud_scheduler_job" "scout_player_snapshot" {
  name        = "${var.resource_prefix}-sched-scout-players"
  project     = var.project_id
  region      = var.region
  description = "Triggers the Scout Cloud Run Job in player-snapshot mode nightly."
  schedule    = var.player_snapshot_cron
  time_zone   = var.player_snapshot_tz

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${var.scout_job_name}:run"

    # Pass --mode=player-snapshot via overrides so we reuse the same job
    # definition for both schedules.
    body = base64encode(jsonencode({
      overrides = {
        containerOverrides = [
          {
            args = ["--mode=player-snapshot"]
          }
        ]
      }
    }))

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = var.scheduler_sa_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  retry_config {
    retry_count = 1
  }
}

# Daily Engine prediction refresh. Runs an hour after the openligadb sync so
# the form-window picks up yesterday's results before we cache predictions for
# the upcoming matchday. No-op if every match in the current season is already
# finished (off-season).
resource "google_cloud_scheduler_job" "engine_refresh_current" {
  count       = var.engine_service_url != "" ? 1 : 0
  name        = "${var.resource_prefix}-sched-engine-refresh"
  project     = var.project_id
  region      = var.region
  description = "Pings the Engine to recompute and cache predictions for the upcoming Bundesliga matchday."
  schedule    = var.engine_refresh_cron
  time_zone   = var.engine_refresh_tz

  http_target {
    http_method = "POST"
    uri         = "${var.engine_service_url}/api/v1/predictions/refresh-current"

    headers = {
      "Content-Type" = "application/json"
    }
  }

  retry_config {
    retry_count = 2
  }
}
