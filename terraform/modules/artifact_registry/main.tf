variable "project_id" {
  type = string
}

variable "region" {
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

variable "scout_sa_email" {
  type = string
}

variable "engine_sa_email" {
  type = string
}

variable "striker_sa_email" {
  type    = string
  default = ""
}

variable "github_deploy_sa_email" {
  type    = string
  default = ""
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_artifact_registry_repository" "kickwise" {
  project       = var.project_id
  location      = var.region
  repository_id = "kickwise"
  description   = "Kickwise container images (playmaker, winger, scout, engine)."
  format        = "DOCKER"
  labels        = var.labels

  cleanup_policies {
    id     = "keep-recent-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-older-than-180d"
    action = "DELETE"
    condition {
      older_than = "15552000s"
    }
  }
}

# Cloud Run service-accounts only need to pull images from the registry.
locals {
  pullers = compact([
    "serviceAccount:${var.playmaker_sa_email}",
    "serviceAccount:${var.winger_sa_email}",
    "serviceAccount:${var.scout_sa_email}",
    "serviceAccount:${var.engine_sa_email}",
    var.striker_sa_email != "" ? "serviceAccount:${var.striker_sa_email}" : ""
  ])

  pushers = compact([
    var.github_deploy_sa_email != "" ? "serviceAccount:${var.github_deploy_sa_email}" : ""
  ])
}

resource "google_artifact_registry_repository_iam_member" "pullers" {
  for_each = toset(local.pullers)

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.kickwise.repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "pushers" {
  for_each = toset(local.pushers)

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.kickwise.repository_id
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

output "repository_id" {
  value = google_artifact_registry_repository.kickwise.repository_id
}

output "repository_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.kickwise.repository_id}"
}
