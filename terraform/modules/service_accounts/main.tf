variable "project_id" {
  type = string
}

variable "resource_prefix" {
  type = string
}

resource "google_service_account" "playmaker" {
  account_id   = "${var.resource_prefix}-sa-playmaker"
  display_name = "Kickwise Playmaker"
  project      = var.project_id
}

resource "google_service_account" "winger" {
  account_id   = "${var.resource_prefix}-sa-winger"
  display_name = "Kickwise Winger"
  project      = var.project_id
}

resource "google_service_account" "scout" {
  account_id   = "${var.resource_prefix}-sa-scout"
  display_name = "Kickwise Scout"
  project      = var.project_id
}

resource "google_service_account" "scheduler" {
  account_id   = "${var.resource_prefix}-sa-scheduler"
  display_name = "Kickwise Scheduler"
  project      = var.project_id
}

resource "google_service_account" "engine" {
  account_id   = "${var.resource_prefix}-sa-engine"
  display_name = "Kickwise Engine (Phase 2)"
  project      = var.project_id
}


output "playmaker_sa_email" {
  value = google_service_account.playmaker.email
}

output "winger_sa_email" {
  value = google_service_account.winger.email
}

output "scout_sa_email" {
  value = google_service_account.scout.email
}

output "scheduler_sa_email" {
  value = google_service_account.scheduler.email
}

output "engine_sa_email" {
  value = google_service_account.engine.email
}

