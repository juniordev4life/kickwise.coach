variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "playmaker_sa_email" {
  type    = string
  default = ""
}

variable "engine_sa_email" {
  type    = string
  default = ""
}

resource "google_firestore_database" "default" {
  project                     = var.project_id
  name                        = "(default)"
  location_id                 = var.region
  type                        = "FIRESTORE_NATIVE"
  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
  deletion_policy             = "DELETE"
}

# Firestore native uses Datastore IAM. roles/datastore.user grants read/write
# on documents; the dataset OWNER/READER setup in BigQuery doesn't apply here.
resource "google_project_iam_member" "playmaker_firestore_user" {
  count   = var.playmaker_sa_email != "" ? 1 : 0
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${var.playmaker_sa_email}"

  depends_on = [google_firestore_database.default]
}

resource "google_project_iam_member" "engine_firestore_user" {
  count   = var.engine_sa_email != "" ? 1 : 0
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${var.engine_sa_email}"

  depends_on = [google_firestore_database.default]
}

output "database_name" {
  value = google_firestore_database.default.name
}
