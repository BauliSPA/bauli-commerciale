# Foundation: Data Admins
resource "google_project_iam_member" "admins_binding" {
  for_each = toset(local.admins_roles)

  project = local.project_id
  role    = each.value
  member  = "group:data_admins@bauli.it"
}

# Foundation: Data Developers
resource "google_project_iam_member" "developers_binding" {
  for_each = toset(local.developers_roles)

  project = local.project_id
  role    = each.value
  member  = "group:data_developers@bauli.it"
}

# Foundation: Data Maintainers
resource "google_project_iam_member" "maintainers_binding" {
  for_each = toset(local.maintainers_roles)

  project = local.project_id
  role    = each.value
  member  = "group:data_maintaners@bauli.it" # Typo error in the group creation (google Groups), not here
}
