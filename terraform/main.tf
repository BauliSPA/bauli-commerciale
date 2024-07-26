locals {
  config = yamldecode(file("_bauli_commercial.yml"))

  project_id = local.config.project_id
  location   = local.config.location

  landing_bucket_name          = local.config.landing_bucket.name
  landing_bucket_location      = local.config.landing_bucket.location
  landing_bucket_storage_class = local.config.landing_bucket.storage_class
  source_format                = local.config.landing_bucket.source_format
  avro_files_folder            = local.config.landing_bucket.avro_files_folder
  avro_files                   = local.config.landing_bucket.avro_files

  dataset_name = local.config.bigquery.dataset_name
  dataset_location = local.config.bigquery.dataset_location
  schemas      = local.config.bigquery.schemas

  service_account_name  = local.config.service_account.name
  sa_private_key_type   = local.config.service_account.private_key_type
  sa_key_algorithm      = local.config.service_account.key_algorithm
  service_account_roles = local.config.service_account.roles

  enabled_apis = local.config.enabled_apis

  terraform_state_bucket_name     = local.config.state_bucket_terraform.name
  terraform_state_bucket_location = local.config.state_bucket_terraform.location
  terraform_state_bucket_class    = local.config.state_bucket_terraform.storage_class
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "bli-bi-commerciale-test-001-terraform-state-bucket" # This cannot be dynamically computed
    prefix = "terraform/state"
  }
}

provider "google" {
  project = local.project_id
  region  = local.location
}

