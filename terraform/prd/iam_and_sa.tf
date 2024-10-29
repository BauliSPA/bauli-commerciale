# SA and roles
resource "google_service_account" "sa" {
  account_id   = "${local.project_id}-sa"
  display_name = "${local.project_id}-sa"
}

# Deprecated: this was to get the key of the service account for SAP Datasphere connection (don't delete)
resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.sa.id
  private_key_type   = local.sa_private_key_type
  key_algorithm      = local.sa_key_algorithm

  provisioner "local-exec" {
    command = <<EOT
      echo ${google_service_account_key.sa_key.private_key} | base64 --decode > ../sa_keys/sa_key_prd.json
    EOT
  }

  depends_on = [google_service_account.sa]
}
# -------------------------------------------------------------------------------------------

resource "google_project_iam_member" "roles" {
  for_each = toset(local.service_account_roles)
  project  = local.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa.email}"

  depends_on = [google_service_account.sa]
}

