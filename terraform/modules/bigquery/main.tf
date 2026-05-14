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

# Phase 1 tables — created from DDL files in ../../sql/
locals {
  phase1_table_files = [
    "001_create_seasons.sql",
    "002_create_teams.sql",
    "003_create_matches.sql",
    "004_create_players.sql"
  ]
}

resource "google_bigquery_job" "create_table" {
  for_each = toset(local.phase1_table_files)

  project  = var.project_id
  location = var.region

  job_id = "create_${replace(each.key, ".sql", "")}_${formatdate("YYYYMMDDhhmmss", timestamp())}"

  query {
    query = file("${path.module}/../../sql/${each.key}")

    use_legacy_sql = false

    destination_table {
      project_id = var.project_id
      dataset_id = google_bigquery_dataset.main.dataset_id
      # table_id is implicit from the DDL CREATE TABLE statement
      table_id = replace(replace(each.key, "^00[0-9]_create_", ""), ".sql", "")
    }

    write_disposition  = "WRITE_EMPTY"
    create_disposition = "CREATE_IF_NEEDED"
  }

  # Re-running this with create_disposition=CREATE_IF_NEEDED means
  # an existing table won't be replaced — keeps Terraform idempotent.
  lifecycle {
    ignore_changes = [job_id, query[0].destination_table]
  }
}

output "dataset_id" {
  value = google_bigquery_dataset.main.dataset_id
}

output "dataset_fqn" {
  value = "${var.project_id}.${google_bigquery_dataset.main.dataset_id}"
}
