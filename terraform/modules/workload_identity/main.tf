variable "project_id" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "github_repo_owner" {
  type = string
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.resource_prefix}-pool-github"
  display_name              = "GitHub Actions"
  description               = "Workload Identity Pool for GitHub Actions OIDC"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.resource_prefix}-prov-github"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository_owner == '${var.github_repo_owner}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Deploy-SA für GitHub Actions — eigene SA mit minimalen Rechten
resource "google_service_account" "github_deploy" {
  account_id   = "${var.resource_prefix}-sa-gha-deploy"
  display_name = "GitHub Actions Deploy"
  project      = var.project_id
}

resource "google_service_account_iam_member" "github_actions_can_impersonate" {
  service_account_id = google_service_account.github_deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.owner/${var.github_repo_owner}"
}

# Deploy-Rechte für Cloud Run + Storage (Striker) + Artifact Registry
locals {
  github_deploy_roles = [
    "roles/run.admin",
    "roles/storage.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser"
  ]
}

resource "google_project_iam_member" "github_deploy_roles" {
  for_each = toset(local.github_deploy_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deploy.email}"
}

output "provider_name" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "github_deploy_sa_email" {
  value = google_service_account.github_deploy.email
}
