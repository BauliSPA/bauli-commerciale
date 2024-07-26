resource "google_bigquery_dataset" "dataset" {
  dataset_id = local.dataset_name
  project    = local.project_id
  location   = local.dataset_location
}

resource "google_bigquery_table" "table" {
  count      = length(local.avro_files)
  table_id   = replace(local.avro_files[count.index], ".avro", "")
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  project    = google_bigquery_dataset.dataset.project
  external_data_configuration {
    autodetect    = true
    source_format = local.source_format
    source_uris = [
      "gs://${google_storage_bucket.landing_bucket.name}/${local.avro_files_folder}/${local.avro_files[count.index]}"
    ]
    schema = lookup(local.schemas, replace(local.avro_files[count.index], ".avro", ""), null)
  }
  deletion_protection = false

  depends_on = [google_bigquery_dataset.dataset, google_storage_bucket_object.avro_files_folder]
}
