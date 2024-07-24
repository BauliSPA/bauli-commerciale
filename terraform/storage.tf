resource "google_storage_bucket" "landing_bucket" {
  name          = local.landing_bucket_name
  location      = local.landing_bucket_location
  storage_class = local.landing_bucket_storage_class
}

resource "google_storage_bucket_object" "csv_files_folder" {
  name    = "${local.csv_files_folder}/"
  bucket  = google_storage_bucket.landing_bucket.name
  content = " "

  depends_on = [google_storage_bucket.landing_bucket]
}
