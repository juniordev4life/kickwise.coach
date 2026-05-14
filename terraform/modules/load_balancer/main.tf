variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "striker_bucket_name" {
  type = string
}

variable "playmaker_service_name" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

# Phase 1 LB is minimal: a single public IP, routing to the Striker bucket and the Playmaker
# Cloud Run service. No custom domain — the LB IP is used directly, or callers
# hit the *.run.app URLs of Playmaker/Striker.

resource "google_compute_global_address" "lb_ip" {
  name    = "${var.resource_prefix}-lb-ip"
  project = var.project_id
}

resource "google_compute_backend_bucket" "striker" {
  name        = "${var.resource_prefix}-be-striker"
  project     = var.project_id
  bucket_name = var.striker_bucket_name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    signed_url_cache_max_age_sec = 0
  }
}

resource "google_compute_region_network_endpoint_group" "playmaker_neg" {
  name                  = "${var.resource_prefix}-neg-playmaker"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.playmaker_service_name
  }
}

resource "google_compute_backend_service" "playmaker" {
  name        = "${var.resource_prefix}-be-playmaker"
  project     = var.project_id
  protocol    = "HTTPS"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.playmaker_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "default" {
  name            = "${var.resource_prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_bucket.striker.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_bucket.striker.id

    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.playmaker.id
    }
  }
}

# Phase 1: HTTP only (no custom domain → no managed cert easy path).
# Phase 2 wird auf HTTPS + Managed Cert umgestellt sobald eine Custom-Domain existiert.
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.resource_prefix}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.resource_prefix}-fr-http"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}
