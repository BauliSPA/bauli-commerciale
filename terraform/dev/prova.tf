resource "google_storage_bucket" "test_bucket" {
  name          = "${local.project_id}-test"
  location      = local.landing_bucket_location
  storage_class = local.landing_bucket_storage_class
  force_destroy = true
}
