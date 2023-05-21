# This block sets up what backend should be used for Terraform. In this case, we are using Google Cloud Storage.
terraform {
  backend "gcs" {
    bucket      = "peerlab-tf-state"
    prefix      = "terraform/state/environments/staging"
    credentials = "credentials.json" # The path to the JSON key file for the Service Account Terraform will use to manage its state
  }
}
