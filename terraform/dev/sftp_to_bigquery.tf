# # Static IP Configuration
# resource "google_compute_address" "static_ip" {
#   name   = local.static_ip.name
#   region = local.static_ip.region
# }

# # Cloud Function for SFTP to BigQuery Transfer
# resource "google_cloudfunctions_function" "sftp_transfer_function" {
#   name        = local.cloud_function.name
#   region      = local.cloud_function.region
#   runtime     = local.cloud_function.runtime
#   entry_point = local.cloud_function.entry_point
#   available_memory_mb = 256

#   # Define environment variables for the function
#   environment_variables = {
#     SFTP_SERVER       = local.cloud_function.environment_variables.SFTP_SERVER
#     SFTP_USER         = local.cloud_function.environment_variables.SFTP_USER
#     SFTP_PASSWORD     = local.cloud_function.environment_variables.SFTP_PASSWORD
#     BIGQUERY_DATASET  = local.cloud_function.environment_variables.BIGQUERY_DATASET
#     BIGQUERY_TABLE    = local.cloud_function.environment_variables.BIGQUERY_TABLE
#   }

#   timeout = local.cloud_function.timeout

#   vpc_connector = google_compute_address.static_ip.id

#   source_archive_bucket = google_storage_bucket.source_bucket.name
#   source_archive_object = google_storage_bucket_object.source_code.name

#   # Depends on Static IP and Storage Bucket
#   depends_on = [
#     google_compute_address.static_ip,
#     google_storage_bucket.source_bucket,
#     google_storage_bucket_object.source_code
#   ]
# }

# # Scheduler for invoking the Cloud Function
# resource "google_cloud_scheduler_job" "sftp_to_bigquery_scheduler" {
#   name     = local.scheduler.name
#   schedule = local.scheduler.schedule
#   time_zone = local.scheduler.time_zone

#   http_target {
#     http_method = "POST"
#     uri         = google_cloudfunctions_function.sftp_transfer_function.https_trigger_url
#     oidc_token {
#       service_account_email = google_service_account.cloud_function_sa.email
#     }
#   }

#   # Depends on Cloud Function
#   depends_on = [
#     google_cloudfunctions_function.sftp_transfer_function
#   ]
# }

# # Google Cloud Storage bucket for function source code
# resource "google_storage_bucket" "source_bucket" {
#   name     = "${local.project_id}-function-source"
#   location = local.location
# }

# # Create the zip file for Cloud Function source code inside the cf_for_sftp_transfer directory
# resource "null_resource" "create_zip" {
#   provisioner "local-exec" {
#     command = "cd ${path.module}/cf_for_sftp_transfer && zip -r function-source.zip ."
#   }
# }

# # Google Cloud Storage bucket object for source code
# resource "google_storage_bucket_object" "source_code" {
#   name   = "function-source.zip"
#   bucket = google_storage_bucket.source_bucket.name
#   source = "${path.module}/cf_for_sftp_transfer/function-source.zip"

#   # Make sure the zip is created before uploading
#   depends_on = [null_resource.create_zip]
# }

# # Service Account for the Cloud Function
# resource "google_service_account" "cloud_function_sa" {
#   account_id   = "sftp-transfer-sa"
#   display_name = "Service account for SFTP to BigQuery Cloud Function"
# }

# # Grant roles to the Service Account for necessary permissions
# resource "google_project_iam_member" "cloud_function_sa_bigquery" {
#   project = local.project_id
#   role    = "roles/bigquery.dataEditor"
#   member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"

#   # Depends on Service Account
#   depends_on = [
#     google_service_account.cloud_function_sa
#   ]
# }

# resource "google_project_iam_member" "cloud_function_sa_storage" {
#   project = local.project_id
#   role    = "roles/storage.objectAdmin"
#   member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"

#   # Depends on Service Account
#   depends_on = [
#     google_service_account.cloud_function_sa
#   ]
# }
