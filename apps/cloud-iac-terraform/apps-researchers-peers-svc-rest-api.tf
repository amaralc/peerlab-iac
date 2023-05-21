# Define local variables
locals {
  repo_name              = "peerlab"                        # The name of the source repository
  repo_owner             = "amaralc"                        # The GitHub owner's username
  app_name               = "researchers-peers-svc-rest-api" # The name of the application
  dockerfile_folder_path = "apps/researchers/peers/svc"     # The path to the Dockerfile from the root of the repository
  commit_hash_file       = "${path.module}/.commit_hash"    # The file where the commit hash of that repository will be stored
}

# Fetch the current commit hash and write it to a file
resource "null_resource" "get_commit_hash" {
  provisioner "local-exec" {
    command = "git rev-parse HEAD > ${local.commit_hash_file}"
  }
}

# Read the commit hash from the file
data "local_file" "commit_hash" {
  filename   = local.commit_hash_file
  depends_on = [null_resource.get_commit_hash]
}

# Trim the commit hash and store it in a local variable (for use in cloud run)
locals {
  image_tag = trimspace(data.local_file.commit_hash.content)
}

resource "google_service_account" "researchers-peers-svc" {
  account_id   = local.app_name
  display_name = "Service admin account"
  project      = var.project_id
}

resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.researchers-peers-svc.email}"
}

# Assign the service account the Cloud Run Admin role
resource "google_project_iam_member" "run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.researchers-peers-svc.email}"
}

# Assign the service account the Cloud Run Invoker role
resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.researchers-peers-svc.email}"
}

# Assign the service account the Cloud Build Editor role
resource "google_project_iam_member" "cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.researchers-peers-svc.email}"
}

# Create the Service Account Key
resource "google_service_account_key" "researchers-peers-svc-key" {
  service_account_id = google_service_account.researchers-peers-svc.name
}

# Create the secret in Secret Manager
resource "google_secret_manager_secret" "researchers-peers-svc-secret" {
  secret_id = "researchers-peers-svc-secret"
  project   = var.project_id

  replication {
    automatic = true
  }
}

# Add the service account key as a secret version
resource "google_secret_manager_secret_version" "researchers-peers-svc-secret-v1" {
  secret      = google_secret_manager_secret.researchers-peers-svc-secret.id
  secret_data = base64encode(google_service_account_key.researchers-peers-svc-key.private_key)
}

# Fetch the service account key from Google Secret Manager
data "google_secret_manager_secret_version" "researchers-peers-svc_access_secret" {
  # The project in which the secret was created
  project = var.project_id

  # The secret_id corresponds to the name of the secret you created in Secret Manager
  secret = google_secret_manager_secret.researchers-peers-svc-secret.secret_id

  # The version of the secret to fetch. "latest" would fetch the latest version of the secret
  version = "latest"

  # Waits for the secret to be available
  depends_on = [google_secret_manager_secret_version.researchers-peers-svc-secret-v1]
}

# This resource block defines a Google Cloud Build trigger that will react to pushes on the branch "feature/DIS-522-move-to-gcp"
resource "google_cloudbuild_trigger" "default" {
  # Name of the trigger
  name = "push-on-branch-feature-DIS-522-move-to-gcp"

  # Project ID where the trigger will be created
  project = var.project_id

  # Disable status of the trigger
  disabled = false

  # GitHub configuration
  github {
    # GitHub owner's username
    owner = local.repo_owner

    # Name of the source repository
    name = local.repo_name

    # Configuration for triggering on a push to a specific branch
    push {
      # Regex pattern for the branch name to trigger on
      branch = "^feature/DIS-522-move-to-gcp$"
    }
  }

  # List of file/directory patterns in the source repository that are included in the source. Here, it includes all files and directories.
  included_files = ["**"]

  # Defines the build configuration
  build {
    # Each step in the build is represented as a list of commands
    step {
      # Name of the builder (the Docker image on Google Cloud) that will execute this build step
      name = "gcr.io/cloud-builders/docker"

      # Arguments to pass to the build step
      args = [
        "build",                                                         # Docker command to build an image from a Dockerfile
        "-t",                                                            # Tag the image with a name and optionally a tag in the 'name:tag' format
        "gcr.io/${var.project_id}/${local.app_name}:latest",             # Tag the image with the latest tag
        "-t",                                                            # Tag the image with a name and optionally a tag in the 'name:tag' format
        "gcr.io/${var.project_id}/${local.app_name}:${local.image_tag}", # Tag the image with the commit SHA
        "-f",                                                            # Name of the Dockerfile (Default is 'PATH/Dockerfile')
        "${local.dockerfile_folder_path}/Dockerfile",                    # Path to the Dockerfile
        ".",                                                             # The build context is the current directory
      ]
    }

    # List of Docker images to be pushed to the registry upon successful completion of all build steps
    images = [
      "gcr.io/${var.project_id}/${local.app_name}:latest",            # Image with the latest tag
      "gcr.io/${var.project_id}/${local.app_name}:${local.image_tag}" # Image with the commit SHA tag
    ]
  }
}


# # This resource block defines a Google Cloud Run service. This service will host the Docker image created by the Google Cloud Build trigger.
# resource "google_cloud_run_service" "default" {
#   # Name of the service
#   name = local.app_name

#   # The region where the service will be located
#   location = var.region

#   # Defining the service template
#   template {
#     spec {
#       # The service account to be used by the service
#       service_account_name = google_service_account.researchers-peers-svc.email

#       # The Docker image to use for the service
#       containers {
#         # The docker image is pulled from GCR using the project ID, app name and the image tag which corresponds to the commit hash
#         image = "gcr.io/${google_cloudbuild_trigger.default.project}/${local.app_name}:${local.image_tag}"
#       }
#     }
#   }

#   # Defines the service traffic parameters
#   traffic {
#     # The percent of traffic this version of the service should receive
#     percent = 100

#     # Whether traffic should be directed to the latest revision
#     latest_revision = true
#   }

#   depends_on = [google_cloudbuild_trigger.default]
# }

# # This block defines a Cloud Run IAM member. This sets the permissions for who can access the Cloud Run service.
# resource "google_cloud_run_service_iam_member" "public" {
#   service  = google_cloud_run_service.default.name     # The name of the service to which the IAM policy will be applied
#   location = google_cloud_run_service.default.location # The location of the service to which the IAM policy will be applied
#   role     = "roles/run.invoker"                       # The role to be granted
#   member   = "allUsers"                                # The user, group, or service account who will have the role granted. In this case, all users.
# }
