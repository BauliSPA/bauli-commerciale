resource "google_bigquery_dataset" "dataset" {
  for_each = local.bigquery_datasets

  project    = local.project_id
  dataset_id = each.key
  location   = each.value.location

}
