resource "google_storage_bucket" "landing_bucket" {
  name          = local.landing_bucket_name
  location      = local.landing_bucket_location
  storage_class = local.landing_bucket_storage_class
  force_destroy = true
}

resource "google_storage_bucket_object" "avro_files_folder" {
  name    = "${local.avro_files_folder}/"
  bucket  = google_storage_bucket.landing_bucket.name
  content = " "

  depends_on = [google_storage_bucket.landing_bucket]
}
