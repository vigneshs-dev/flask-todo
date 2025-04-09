#!/bin/bash

# Exit immediately if a command fails
set -e

echo "Starting cleanup of ECS Fargate deployment..."

# === Move into infra folder ===
# cd infra
cd terraform

# === Get outputs before destruction ===
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
CLUSTER_NAME="flask-todo-cluster"
SERVICE_NAME="flask-todo-service"

# === Scale down ECS service before destruction ===
if [ ! -z "$CLUSTER_NAME" ] && [ ! -z "$SERVICE_NAME" ]; then
  echo "Scaling down ECS service..."
  aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --region $AWS_REGION || echo "Failed to scale down ECS service, continuing anyway"
  
  echo "Waiting for tasks to stop (this may take a minute)..."
  sleep 30
fi

# === Clean up ECR repository images ===
if [ ! -z "$ECR_REPO_URL" ]; then
  echo "Cleaning up ECR repository images..."
  REPO_NAME=$(basename $ECR_REPO_URL)
  
  # Delete all images in the repository
  aws ecr list-images --repository-name $REPO_NAME --region $AWS_REGION --query 'imageIds[*]' --output json | \
  aws ecr batch-delete-image --repository-name $REPO_NAME --region $AWS_REGION --image-ids file:///dev/stdin || echo "Failed to delete ECR images, continuing anyway"
fi

# === Destroy Terraform-managed infrastructure ===
echo "Destroying AWS resources with Terraform..."

# Destroy all Terraform-managed resources
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "✅ ECS Fargate, RDS, and related infra destroyed successfully."
else
    echo "❌ Terraform destroy failed."
    exit 1
fi

echo "Cleanup completed successfully!"