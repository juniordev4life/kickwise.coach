variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_storage_bucket" "striker" {
  name          = "${var.resource_prefix}-bucket-striker"
  project       = var.project_id
  location      = var.region
  force_destroy = false
  labels        = var.labels

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "striker_public_read" {
  bucket = google_storage_bucket.striker.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

output "striker_bucket_name" {
  value = google_storage_bucket.striker.name
}

output "striker_bucket_self_link" {
  value = google_storage_bucket.striker.self_link
}
