# Landing bucket
resource "google_storage_bucket" "landing_bucket" {
  name          = "${local.project_id}-${local.landing_bucket_name}"
  location      = local.landing_bucket_location
  storage_class = local.landing_bucket_storage_class
  force_destroy = true
}
