variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "playmaker_image" {
  type = string
}

variable "winger_image" {
  type = string
}

variable "striker_image" {
  type    = string
  default = "gcr.io/cloudrun/hello"
}

variable "playmaker_sa_email" {
  type = string
}

variable "winger_sa_email" {
  type = string
}

variable "striker_sa_email" {
  type = string
}

variable "jwt_secret_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

# Winger — internal-only, called by Playmaker via service-to-service auth
resource "google_cloud_run_v2_service" "winger" {
  name                = "${var.resource_prefix}-run-winger"
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  deletion_protection = false

  template {
    service_account = var.winger_sa_email
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.winger_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "KICKBASE_BASE_URL"
        value = "https://api.kickbase.com"
      }
    }
  }

  labels = var.labels
}

# Playmaker — public, but currently behind LB. Allow public for now to keep the LB simple.
resource "google_cloud_run_v2_service" "playmaker" {
  name                = "${var.resource_prefix}-run-playmaker"
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = var.playmaker_sa_email
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.playmaker_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }

      env {
        name  = "WINGER_URL"
        value = google_cloud_run_v2_service.winger.uri
      }

      env {
        name  = "BQ_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "BQ_DATASET"
        value = "kickwise_main"
      }

      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = var.jwt_secret_id
            version = "latest"
          }
        }
      }
    }
  }

  labels = var.labels
}

# Allow Playmaker SA to invoke the Winger Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "playmaker_invokes_winger" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.winger.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.playmaker_sa_email}"
}

# Allow public to invoke Playmaker
resource "google_cloud_run_v2_service_iam_member" "playmaker_public_invoke" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.playmaker.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Striker — public static SPA hosting via nginx with SPA fallback.
resource "google_cloud_run_v2_service" "striker" {
  name                = "${var.resource_prefix}-run-striker"
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = var.striker_sa_email
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.striker_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  labels = var.labels
}

resource "google_cloud_run_v2_service_iam_member" "striker_public_invoke" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.striker.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "playmaker_service_name" {
  value = google_cloud_run_v2_service.playmaker.name
}

output "playmaker_service_url" {
  value = google_cloud_run_v2_service.playmaker.uri
}

output "winger_service_name" {
  value = google_cloud_run_v2_service.winger.name
}

output "winger_service_url" {
  value = google_cloud_run_v2_service.winger.uri
}

output "striker_service_name" {
  value = google_cloud_run_v2_service.striker.name
}

output "striker_service_url" {
  value = google_cloud_run_v2_service.striker.uri
}
