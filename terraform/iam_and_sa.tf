resource "google_service_account" "sa" {
  account_id   = "${local.project_id}-${local.service_account_name}"
  display_name = "${local.project_id}-${local.service_account_name}"
}

resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.sa.id
  private_key_type   = local.sa_private_key_type
  key_algorithm      = local.sa_key_algorithm

  depends_on = [google_service_account.sa]
}

resource "google_project_iam_member" "roles" {
  for_each = toset(local.service_account_roles)
  project  = local.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa.email}"

  depends_on = [google_service_account.sa]
}

