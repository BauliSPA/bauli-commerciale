resource "google_bigquery_dataset" "dataset" {
  for_each = local.bigquery_datasets

  project    = local.project_id
  dataset_id = each.key
  location   = each.value.location

}

# TODO: Rimuovere la risorsa?

# resource "google_bigquery_table" "table" {
#   for_each = {
#     for dataset_name, dataset_info in local.bigquery_datasets :
#     dataset_name => dataset_info if dataset_info.schemas != null
#   }

#   table_id   = each.key
#   dataset_id = google_bigquery_dataset.dataset[each.key].dataset_id
#   project    = google_bigquery_dataset.dataset.project

#   external_data_configuration {
#     autodetect    = true
#     source_format = local.source_format
#     source_uris = [
#       "gs://${google_storage_bucket.landing_bucket.name}/${local.csv_files_folder}/${local.csv_files[count.index]}"
#     ]
#     schema = lookup(local.schemas, replace(local.csv_files[count.index], ".csv", ""), null)
#   }
#   deletion_protection = false

#   depends_on = [google_bigquery_dataset.dataset, google_storage_bucket_object.csv_files_folder]
# }
