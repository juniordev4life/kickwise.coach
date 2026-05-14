terraform {
  backend "gcs" {
    bucket = "kickwise-prod-tf-state"
    prefix = "kickwise/coach"
  }
}
