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

variable "playmaker_sa_email" {
  type = string
}

variable "winger_sa_email" {
  type = string
}

variable "jwt_secret_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

# Winger — public ingress. Cloud Run's INTERNAL_ONLY mode would force every
# Playmaker -> Winger call to carry an OIDC ID-token in Authorization, but we
# already use Authorization for the Kickbase token. Rather than splitting the
# auth across two headers, Phase 1 lets Winger accept public traffic; the
# Kickbase token requirement in requireKickbaseToken still gates every
# Kickbase call. Tighten this with ID-token auth (and X-Kickbase-Token) once
# Phase 2 work justifies the complexity.
resource "google_cloud_run_v2_service" "winger" {
  name                = "${var.resource_prefix}-run-winger"
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
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

  # Image is rotated by the Winger Match Day workflow. Terraform should not
  # fight CD by reverting to the default image on every apply.
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version
    ]
  }
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

  # Image is rotated by the Playmaker Match Day workflow.
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version
    ]
  }
}

# Allow Playmaker SA to invoke the Winger Cloud Run service. With ingress=ALL
# the public binding below is what actually grants the invoke, but the
# explicit SA binding stays for future use (so we can switch back to
# INTERNAL_ONLY + ID-token auth without re-wiring the IAM).
resource "google_cloud_run_v2_service_iam_member" "playmaker_invokes_winger" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.winger.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.playmaker_sa_email}"
}

# Phase 1: public invoke on Winger. Real auth is the Kickbase token check
# inside Winger; the service has no Kickbase-private capabilities of its own.
resource "google_cloud_run_v2_service_iam_member" "winger_public_invoke" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.winger.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow public to invoke Playmaker
resource "google_cloud_run_v2_service_iam_member" "playmaker_public_invoke" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.playmaker.name
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
