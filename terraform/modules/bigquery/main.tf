variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "playmaker_sa_email" {
  type = string
}

variable "scout_sa_email" {
  type = string
}

variable "engine_sa_email" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_bigquery_dataset" "main" {
  project       = var.project_id
  dataset_id    = var.dataset_id
  friendly_name = "Kickwise Main"
  description   = "Historical and analytical data for the Kickwise project (Bundesliga matches, players, predictions, ...)."
  location      = var.region
  labels        = var.labels

  access {
    role          = "OWNER"
    user_by_email = var.scout_sa_email
  }

  access {
    role          = "WRITER"
    user_by_email = var.engine_sa_email
  }

  access {
    role          = "READER"
    user_by_email = var.playmaker_sa_email
  }

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
}

# Project-level permissions:
# Dataset access alone doesn't grant bigquery.jobs.create, which the SDK
# requires for any query/load/merge job. Grant the jobUser role on the
# project to Scout (writes, MERGE), Playmaker (reads), and Engine (Phase 2
# writes).
resource "google_project_iam_member" "scout_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.scout_sa_email}"
}

resource "google_project_iam_member" "playmaker_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.playmaker_sa_email}"
}

resource "google_project_iam_member" "engine_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${var.engine_sa_email}"
}

# Phase 1 tables are created from the DDL files under terraform/sql/ by the
# Coach README bootstrap step (bq query). Phase 2+ tables follow the same
# pattern. We don't manage them with google_bigquery_table here because the
# DDL files already capture the partition + cluster setup we want.

output "dataset_id" {
  value = google_bigquery_dataset.main.dataset_id
}

output "dataset_fqn" {
  value = "${var.project_id}.${google_bigquery_dataset.main.dataset_id}"
}
