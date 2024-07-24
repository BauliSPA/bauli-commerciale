resource "google_bigquery_dataset" "dataset" {
  dataset_id = local.dataset_name
  project    = local.project_id
  location   = local.location
}

resource "google_bigquery_table" "table" {
  count      = length(local.csv_files)
  table_id   = replace(local.csv_files[count.index], ".csv", "")
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  project    = google_bigquery_dataset.dataset.project

  external_data_configuration {
    autodetect    = true
    source_format = local.source_format
    source_uris = [
      "gs://${google_storage_bucket.landing_bucket.name}/${google_storage_bucket_object.csv_files_folder.name}${local.csv_files[count.index]}"
    ]
  }

  depends_on = [google_bigquery_dataset.dataset, google_storage_bucket_object.csv_files_folder]
}
