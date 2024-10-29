from sshfs import SSHFileSystem  # type: ignore

from google.cloud import storage, bigquery, secretmanager
import io
import json
import os
from google.cloud import dataform_v1beta1
import time
from google.cloud.exceptions import NotFound

# After any change of the cf you must run the following command:
# zip cf-source.zip main.py requirements.txt
# in order to create the zip file for terraform

# Fetch secret from Secret Manager
# def get_secret(secret_name):
#     """Retrieve the secret from Secret Manager."""
#     client = secretmanager.SecretManagerServiceClient()
#     project_id = os.getenv("GCP_PROJECT_ID", "bli-bi-commerciale-prod-001").replace("env","prod")
#     secret_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"

#     response = client.access_secret_version(name=secret_path)
#     return response.payload.data.decode("UTF-8")

# # SFTP connection
# def sftp_connection(host, username, password, port_number, client_keys=None):
#     """Connect to SFTP server using sshfs."""
#     fs = SSHFileSystem(
#         host,
#         username=username,
#         password=password,
#         port=port_number,
#         client_keys=client_keys, 
#     )
#     print("Connected to SFTP server")
#     return fs

# # Download file from SFTP
# def download_file_from_sftp(ftp_client, remote_file_path, file):
#     """Download file from SFTP into an in-memory buffer."""
#     start_time = time.time()
#     print(f"File {file} download from SFTP start time: {start_time}")
    
#     file_like_object = io.BytesIO()
#     with ftp_client.open(remote_file_path, "rb") as remote_file:
#         file_like_object.write(remote_file.read())
#     file_like_object.seek(0)  # Reset buffer position

#     end_time = time.time()
#     print(f"File {file} download end time: {end_time}")
#     print(f"Time taken to download the file {file}: {end_time - start_time} seconds")
#     return file_like_object

# # Upload to GCS
# def upload_to_gcs(bucket_name, source_file_obj, destination_blob_name, file):
#     """Upload a file object to Google Cloud Storage, replacing the existing one if it exists."""
#     storage_client = storage.Client()
#     bucket = storage_client.bucket(bucket_name)
#     blob = bucket.blob(destination_blob_name)

#     # Check and delete the existing file
#     try:
#         blob.delete()
#         print(f"Existing file {destination_blob_name} deleted from GCS.")
#     except NotFound:
#         print(f"No existing file found for {destination_blob_name} in GCS.")

#     # Upload the new file
#     start_time = time.time()
#     print(f"File {file} upload start time: {start_time}")
#     blob.upload_from_file(source_file_obj, content_type='text/csv')
#     end_time = time.time()

#     print(f"File uploaded to GCS: {destination_blob_name}")
#     print(f"File {file} upload end time: {end_time}")
#     print(f"Time taken to upload file {file} to GCS: {end_time - start_time} seconds")

#     # Wait for the new file to become accessible
#     time.sleep(5)  # Delay to ensure file is propagated and accessible
#     new_blob = bucket.get_blob(destination_blob_name)
#     if new_blob:
#         print(f"New file {destination_blob_name} is now accessible in GCS. Size: {new_blob.size} bytes.")
#     else:
#         raise RuntimeError(f"New file {destination_blob_name} is not accessible in GCS after upload.")

# # Load schema from JSON configuration in GCS
# def load_schema_from_config(bucket_name, config_path, table_name):
#     """Load table schema from JSON configuration in GCS."""
#     storage_client = storage.Client()
#     bucket = storage_client.bucket(bucket_name)
#     blob = bucket.blob(config_path)

#     config_data = json.loads(blob.download_as_text())
#     for table in config_data.get("tables", []):
#         if table["table_name"] == table_name:
#             print(f"Schema found for table '{table_name}'")
#             return [
#                 bigquery.SchemaField(
#                     col["id"].lower(), col["type"], description=col.get("description", "")
#                 )
#                 for col in sorted(table["columns"], key=lambda x: x["order"])
#             ]
#     raise ValueError(f"Schema for table '{table_name}' not found in config.")

# # Upload data to BigQuery
# def upload_to_bigquery(bucket_name, gcs_file_path, dataset_name, table_name, schema, file_name):
#     """Load data from GCS to BigQuery with a given schema."""
#     client = bigquery.Client()

#     uri = f"gs://{bucket_name}/{gcs_file_path}"
#     table_id = f"{client.project}.{dataset_name}.{table_name}"

#     # Check if the file_name is "mtx_business_unit.txt" and configure the skip_leading_rows accordingly
#     skip_rows = 0 if file_name == "mtx_business_unit.txt" else 1

#     job_config = bigquery.LoadJobConfig(
#         schema=schema,
#         source_format=bigquery.SourceFormat.CSV,
#         skip_leading_rows=skip_rows,
#         field_delimiter='\t',
#         quote_character='',
#         write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE  
#     )

#     load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
#     load_job.result()

#     print(f"Table {table_name} loaded successfully in dataset {dataset_name}.")

# Function to trigger all actions in Dataform workspace using the Dataform API
def run_workflow(project, location, repo_name, workflow_config_name):
    """Trigger the Dataform workflow configuration execution."""
    df_client = dataform_v1beta1.DataformClient()

    repo_uri = f'projects/{project}/locations/{location}/repositories/{repo_name}'
    workflow_config = f'projects/{project}/locations/{location}/repositories/{repo_name}/workflowConfigs/{workflow_config_name}'

    try:
        request = dataform_v1beta1.CreateWorkflowInvocationRequest(
            parent=repo_uri,
            workflow_invocation=dataform_v1beta1.types.WorkflowInvocation(
                workflow_config=workflow_config
            )
        )

        response = df_client.create_workflow_invocation(request=request)
        name = response.name
        print(f"Triggered Dataform workflow '{workflow_config_name}' successfully with invocation name: {name}")
    except Exception as e:
        print(f"Failed to trigger Dataform workflow '{workflow_config_name}'. Error: {str(e)}")

# Entry point for the Cloud Function
def main(request):
    request_json = request.get_json()

    if not request_json or 'file_name' not in request_json:
        raise ValueError("Request must contain 'file_name'.")

    file_name = request_json['file_name']

    # # SFTP server details
    # sftp_host = "88.42.161.38"
    # sftp_username = "sdg"
    # sftp_password = get_secret("sftp_password")
    # sftp_port = 22

    # # Connect to SFTP server
    # fs = sftp_connection(sftp_host, sftp_username, sftp_password, sftp_port)

    # # Download file
    # remote_file_path = f"files/{file_name}"
    # file_like_object = download_file_from_sftp(fs, remote_file_path, file_name)

    # # GCS upload
    # bucket_name = "bli-bi-commerciale-prod-001-landing"
    # gcs_file_path = f"sftp_tables/{file_name}"
    # upload_to_gcs(bucket_name, file_like_object, gcs_file_path, file_name)

    # # BigQuery schema load
    # config_path = "sftp_tables/tables_config"
    table_name = os.path.splitext(file_name)[0].replace(' ', '_').lower()
    table_name_with_prefix = f"{table_name}"
    # schema = load_schema_from_config(bucket_name, config_path, table_name)

    # # Upload to BigQuery
    # dataset_name = "landing"
    # upload_to_bigquery(bucket_name, gcs_file_path, dataset_name, table_name_with_prefix, schema, file_name)

    # Trigger Dataform workflow
    project = os.getenv("GCP_PROJECT_ID", "bli-bi-commerciale-prod-001").replace("env","prod")
    location = "europe-west8"
    repo_name = "dataform-bauli-dwh-commerciale"
    run_workflow(project, location, repo_name, table_name_with_prefix)

    return "Process completed successfully.", 200
