variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "scout_image" {
  type = string
}

variable "scout_sa_email" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_cloud_run_v2_job" "scout" {
  name     = "${var.resource_prefix}-job-scout"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = var.scout_sa_email
      max_retries     = 2
      timeout         = "1800s"

      containers {
        image = var.scout_image

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }

        env {
          name  = "BQ_PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "BQ_DATASET"
          value = var.dataset_id
        }

        env {
          name  = "SCOUT_MODE"
          value = "current-season"
        }
      }
    }
  }

  labels = var.labels
}

output "scout_job_name" {
  value = google_cloud_run_v2_job.scout.name
}

output "scout_job_id" {
  value = google_cloud_run_v2_job.scout.id
}
