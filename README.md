Building a golden iis image with Cloud Build based on work done [here].(https://cloud.google.com/community/tutorials/create-cloud-build-image-factory-using-packer)
## Enable the required services

    gcloud services enable cloudapis.googleapis.com \
     compute.googleapis.com servicemanagement.googleapis.com \
     storage-api.googleapis.com cloudbuild.googleapis.com \
     secretmanager.googleapis.com

## Set environment variables

    PROJECT=$(gcloud config get-value project)

## Managing secrets for parameters using Secret Manager
You use Secret Manager to store your input values for Packer in a secure and modular way. Although it's easier to simply hard-code parameters into the Packer template file, using a central source of truth like a secret manager increases manageability and reuseability among teams.

Create your secrets using the following commands:

    echo -n "windows-2019" | gcloud secrets create image_factory-image_family --replication-policy="automatic" --data-file=-

    echo -n "golden-windows" | gcloud secrets create image_factory-image_name --replication-policy="automatic" --data-file=-

    echo -n "n1-standard-1" | gcloud secrets create image_factory-machine_type --replication-policy="automatic" --data-file=-

    echo -n "asia-southeast1" | gcloud secrets create image_factory-region --replication-policy="automatic" --data-file=-

    echo -n "asia-southeast1-a" | gcloud secrets create image_factory-zone --replication-policy="automatic" --data-file=-

    echo -n "default" | gcloud secrets create image_factory-network --replication-policy="automatic" --data-file=-

    echo -n "allow-winrm-ingress-to-packer" | gcloud secrets create image_factory-tags --replication-policy="automatic" --data-file=-

## Create a new VPC firewall to allow WinRM for Packer
Before you can provision using the WinRM (Windows Remote Management) communicator, you need to allow traffic through Google's firewall on the WinRM port (tcp:5986). This creates a new firewall called allow-winrm-ingress-to-packer that is stored with Secret Manager and used by Cloud Build in the cloudbuild.yaml configuration file.

    gcloud compute firewall-rules create allow-winrm-ingress-to-packer \
        --allow tcp:5986 --target-tags allow-winrm-ingress-to-packer

## Give the Cloud Build service account permissions through an IAM role
Find the Cloud Build service account and add the editor role to it (in practice, use least privilege roles). You also grant the secretmanager.secretAccessor role for Secret Manager.

    CLOUD_BUILD_ACCOUNT=$(gcloud projects get-iam-policy $PROJECT --filter="(bindings.role:roles/cloudbuild.builds.builder)"  --flatten="bindings[].members" --format="value(bindings.members[])")

    gcloud projects add-iam-policy-binding $PROJECT \
        --member $CLOUD_BUILD_ACCOUNT \
        --role roles/editor

    gcloud projects add-iam-policy-binding $PROJECT \
        --member $CLOUD_BUILD_ACCOUNT \
        --role roles/secretmanager.secretAccessor

## Add the Packer Cloud Build image to your project
Get the builder from the community repository and submit it to your project. This allows Cloud Build to use a Docker container that contains the Packer binaries.

    project_dir=$(pwd)
    cd /tmp
    git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
    cd cloud-builders-community/packer
    gcloud builds submit --config cloudbuild.yaml
    rm -rf /tmp/cloud-builders-community
    cd $project_dir

## Trigger Cloud Build to build a new image with each commit

1. Connect your repository to Cloud Build
1. Create a trigger
