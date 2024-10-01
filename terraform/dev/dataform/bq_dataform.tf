locals {
  bq_datasets = { for d in var.bigquery : d.dataset_name => d.dataset_location }
}

# BigQuery datasets: landing, curated, public for Dataform
resource "google_bigquery_dataset" "datasets" {
  for_each      = local.bq_datasets
  
  dataset_id    = each.key
  friendly_name = each.key
  location      = each.value
  project       = var.project_id
}
