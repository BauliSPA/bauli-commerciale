# bauli-commerciale

Repository with all the infrastructure necessary for the connection between SAP Datasphere, Risorsa, Board and Google BigQuery.
Everything is handled in a centralized way via Terraform.

## Directory Structure

```bash
.
├── README.md
├── .github
├── .gitignore
└── terraform
    ├── _bauli_commercial.yml
    ├── dev
    |   ├── apis.tf
    |   ├── bigquery.tf
    |   ├── foundation.tf
    |   ├── iam_and_sa.tf
    |   ├── main.tf
    |   ├── secrets.tf
    |   ├── sftp_connector.tf
    |   ├── state_bucket.tf
    |   ├── storage.tf
    |   └── dataform
    |       ├── bq_dataform.tf
    |       ├── dataform.tf
    |       └── variables.tf
    └── prd
        ├── apis.tf
        ├── bigquery.tf
        ├── foundation.tf
        ├── iam_and_sa.tf
        ├── main.tf
        ├── secrets.tf
        ├── sftp_connector.tf
        ├── state_bucket.tf
        ├── storage.tf
        └── dataform
            ├── bq_dataform.tf
            ├── dataform.tf
            └── variables.tf
