# Foundation: Data Admins
resource "google_project_iam_binding" "admins_binding" {
  project = local.project_id
  role    = each.value

  for_each = toset(local.admins_roles)

  members = [
    "group:data_admins@bauli.it",
  ]
}

# Foundation: Data Developers
resource "google_project_iam_binding" "developers_binding" {
  project = local.project_id
  role    = each.value

  for_each = toset(local.developers_roles)

  members = [
    "group:data_developers@bauli.it",
  ]
}

# Foundation: Data Maintainers
resource "google_project_iam_binding" "maintainers_binding" {
  project = local.project_id
  role    = each.value

  for_each = toset(local.maintainers_roles)

  members = [
    "group:data_maintaners@bauli.it", # Typo error in the group creation, not here # TODO: è possibile rinominare il gruppo creato?
  ]
}
