# Landing bucket
resource "google_storage_bucket" "landing_bucket" {
  name          = "${local.project_id}-${local.landing_bucket_name}"
  location      = local.landing_bucket_location
  storage_class = local.landing_bucket_storage_class
  force_destroy = true
}

# Bucket object with the tables configuration
resource "google_storage_bucket_object" "config_object" {
  name         = "sftp_tables/${local.bucket_object.name}"
  bucket       = google_storage_bucket.landing_bucket.name
  source       = local.bucket_object.source
  content_type = local.bucket_object.content_type
}