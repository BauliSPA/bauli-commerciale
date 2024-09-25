# bauli-commerciale

Repository with all the infrastructure necessary for the connection between SAP Datasphere, Risorsa, Board and Google BigQuery.
Everything is handled in a centralized way via Terraform.

## Directory Structure

```bash
.
├── README.md
├── .gitignore
└── terraform
    ├── _bauli_commercial.yml
    └── dev
        ├── apis.tf
        ├── bigquery.tf
        ├── dataform.tf
        ├── iam_and_sa.tf
        ├── main.tf
        ├── state_bucket.tf
        └── storage.tf
