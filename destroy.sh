#!/bin/bash

# Exit immediately if a command fails
set -e

# === Stop and remove Docker container ===
echo "Stopping and removing Docker container..."
docker stop flask-todo-server 2>/dev/null || echo "Container already stopped"
docker rm flask-todo-server 2>/dev/null || echo "Container already removed"

# === Optional: Remove Docker image ===
echo "Removing Docker image..."
docker rmi flask-todo-server 2>/dev/null || echo "Image already removed or doesn't exist"

# === Move into infra folder ===
cd infra

# === Get ECR repository URL before destruction (optional) ===
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

if [ ! -z "$ECR_REPO_URL" ]; then
  echo "Cleaning up ECR repository images..."
  # Delete all images in the repository
  aws ecr list-images --repository-name $(basename $ECR_REPO_URL) --region $AWS_REGION --query 'imageIds[*]' --output json | \
  aws ecr batch-delete-image --repository-name $(basename $ECR_REPO_URL) --region $AWS_REGION --image-ids file:///dev/stdin || echo "Failed to delete ECR images, continuing anyway"
fi

# === Destroy Terraform-managed infrastructure ===
echo "Destroying AWS resources with Terraform..."

# Destroy all Terraform-managed resources
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "✅ RDS and related infra destroyed successfully."
else
    echo "❌ Terraform destroy failed."
    exit 1
fi

echo "Cleanup completed successfully!"