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

resource "google_project_iam_member" "scheduler_can_invoke_jobs" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${var.scheduler_sa_email}"
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
