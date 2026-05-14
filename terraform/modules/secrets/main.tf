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

# Initial empty version — must be filled manually via:
#   echo -n "<random-256-bit-secret>" | gcloud secrets versions add ... --data-file=-
# Terraform doesn't manage the version content.

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
