variable "project_id" {
  type = string
}

variable "site_id" {
  type        = string
  description = "Firebase Hosting site ID; default subdomain becomes <site_id>.web.app."
}

variable "github_deploy_sa_email" {
  type = string
}

# Enable the Firebase APIs on the GCP project. These take a few minutes to
# fully propagate on the very first run.
resource "google_project_service" "firebase" {
  for_each = toset([
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Promote the GCP project into a Firebase project (one-way, harmless on existing
# Firebase projects).
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.firebase]
}

# Hosting site. The default site is named after the project_id, but creating it
# explicitly gives us a stable handle even when the default site already exists.
resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.site_id

  depends_on = [google_firebase_project.default]
}

# Allow the GitHub Actions deploy SA to push releases to Firebase Hosting.
resource "google_project_iam_member" "github_firebase_admin" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${var.github_deploy_sa_email}"
}

# Firebase Hosting deploys also require Service Usage Consumer for API quota
# accounting and access to the underlying resources.
resource "google_project_iam_member" "github_serviceusage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${var.github_deploy_sa_email}"
}

output "site_id" {
  value = google_firebase_hosting_site.default.site_id
}

output "default_url" {
  value = "https://${google_firebase_hosting_site.default.site_id}.web.app"
}
