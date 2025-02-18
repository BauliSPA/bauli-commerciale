# Create the KeyRing for KMS
resource "google_kms_key_ring" "product_keyring" {
  name     = local.secrets.keyring_name
  location = local.secrets.location
}

# Create a KMS key to encrypt the secret
resource "google_kms_crypto_key" "product_key" {
  name       = local.secrets.key_name
  key_ring   = google_kms_key_ring.product_keyring.id
  depends_on = [google_kms_key_ring.product_keyring]
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# After the creation of keyring and key, uncomment the following lines  #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# 1) create a local temporary file, such as tmp, and paste the secret into it.

# 2) secret: <SEGRETO>

# 3) Command to encrypt the secret using KMS:
#
# gcloud kms encrypt \
#   --project "bli-bi-commerciale-test-001" \
#   --location "europe-west1" \
#   --keyring "product_keyring" \
#   --key "product_key" \
#   --plaintext-file tmp \
#   --ciphertext-file - | base64 -w 0

# 4) Create the data resource for the password decrypted
# Decrypted secrets
data "google_kms_secret" "secret_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAbDBkX6YeCnxrU/zZQWyIsPj09I9YOgu3PimdT8tudilCaM8SOgB/EfjIiZCNMg0U0FzWh+5SZkSfHeSkqxjJ0G/A7WF0CVVv0x1gSPUg/CLGjp93NqBV0f9CbQlJpos=" # Insert here the output of the bash gcloud above
}


# 5) Create the secret in Secret Manager
resource "google_secret_manager_secret" "sftp_password" {
  secret_id = local.secrets.secret_password
  replication {
    auto {}
  }

  depends_on = [google_kms_crypto_key.product_key]
}

# 6) Create the version of the secret with the encrypted content
resource "google_secret_manager_secret_version" "sftp_password_version" {
  secret      = google_secret_manager_secret.sftp_password.id
  secret_data = data.google_kms_secret.secret_decrypted.plaintext

  depends_on = [google_secret_manager_secret.sftp_password]
}

# SSH private key secret for GitHub-Dataform link
# data "google_kms_secret" "ssh_private_key_dev_secret_decrypted" {
#   crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
#   ciphertext = "CiQAbDBkX4YhRkH29kJUzaIIIGD7afTDV/Ueu9Eovz5PO18tyHoShgMAfxH4yKHHxJNQbxwHdu2F6jTcNT9pKubu9T8uTufnNt//f9xPPI6bDnJIlAEJAHTlew4wO9C7+Fl/6UoLFNYv+mpbFPwHgFDhpZJhxD56vfJUAJ7Zzh9rJwvpDek/T+VBG3uVrM3n44g2KWoxqMeTHFKawfZS99tV3QUpT5Tkc8JAx2tTDK+8e41P0viubQTEsksHeX3Fkr5NkdSnCdqYkUXDSU0WghWEFmPXbMXYEeWRSNKVesEUjCRfRyV8cAwdWrP0I3lpYbjskrFjl8YkSqOclGB8ayHotDsWX9i/O4octvootDAU7MaT20F2hbn/Q0j35o299c6EVJFS1Ch3VUcbORz+yZoEbcO8gjvCHit6Sp1S5Sy3QbGNdsFXeiYkY0SjuK0AMVXYhen8KWYJAES3fkgB7oYkN6hZ3JeI2ZBMWDZB38cpf/3Ek5ivtFeRQqqbOgyvNVGvIedtNNKLN8F+j+2WRWSl34MmKA0twG5MUi/8Dol7AQE04q/1Y1kbdikuDEQ="
# }

# resource "google_secret_manager_secret" "ssh_private_key_dev_secret" {
#   secret_id = "ssh-private-key-dev-secret"
#   replication {
#     auto {}
#   }
# }

# resource "google_secret_manager_secret_version" "ssh_private_key_dev_secret_version" {
#   secret      = google_secret_manager_secret.ssh_private_key_dev_secret.id
#   secret_data = data.google_kms_secret.ssh_private_key_dev_secret_decrypted.plaintext

#   depends_on = [google_secret_manager_secret.ssh_private_key_dev_secret]
# }

# Secret for Power BI connection
data "google_kms_secret" "power_bi_password_dev_secret_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAbDBkXzHSp1EEKqaEABWkP1BkijS2BwyodXJaOGdULFZy9o0SUQB/EfjIkanLmyksRM3ezYY8vhgWjcGz8KcWzYyQ8GSH/yqnfWPrX8FFFHE/38YPwJHhzHOdvCZFuMp1aeoNOf+higbR4hR8NwmnjyIThKOpNQ=="
}

resource "google_secret_manager_secret" "power_bi_password_dev_secret" {
  secret_id = "power-bi-password-dev-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "power_bi_password_dev_secret_version" {
  secret      = google_secret_manager_secret.power_bi_password_dev_secret.id
  secret_data = data.google_kms_secret.power_bi_password_dev_secret_decrypted.plaintext

  depends_on = [google_secret_manager_secret.power_bi_password_dev_secret]
}