variable "project_id" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "playmaker_sa_email" {
  type = string
}

variable "winger_sa_email" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_secret_manager_secret" "jwt_secret" {
  project   = var.project_id
  secret_id = "${var.resource_prefix}-secret-jwt"
  labels    = var.labels

  replication {
    auto {}
  }
}

# Cloud Run reads `:latest` at service-create time, so we must seed the secret
# with at least one version. We generate a 64-char random value and write it
# as the initial version. The user can rotate later with:
#   gcloud secrets versions add kickwise-euw3-secret-jwt --data-file=-
# `ignore_changes` keeps Terraform from rotating it on every apply.
resource "random_password" "jwt_secret_initial" {
  length      = 64
  special     = false
  min_lower   = 16
  min_upper   = 16
  min_numeric = 16
}

resource "google_secret_manager_secret_version" "jwt_secret_initial" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret_initial.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret_iam_member" "playmaker_jwt_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jwt_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.playmaker_sa_email}"
}

resource "google_secret_manager_secret" "winger_internal_auth" {
  project   = var.project_id
  secret_id = "${var.resource_prefix}-secret-winger-auth"
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "playmaker_winger_auth_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.winger_internal_auth.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.playmaker_sa_email}"
}

resource "google_secret_manager_secret_iam_member" "winger_winger_auth_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.winger_internal_auth.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.winger_sa_email}"
}

output "jwt_secret_id" {
  value = google_secret_manager_secret.jwt_secret.id
}

output "jwt_secret_name" {
  value = google_secret_manager_secret.jwt_secret.secret_id
}

output "winger_internal_auth_secret_name" {
  value = google_secret_manager_secret.winger_internal_auth.secret_id
}
