# #!/bin/bash

# # Return when there is an error
# set -e

# # Move to infra and apply terraform
# echo "Applying Terraform..."
# cd infra
# terraform apply -auto-approve

# # Grab the outputs
# RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
# ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
# AWS_REGION=$(terraform output -raw aws_region)
# DB_USERNAME=$(terraform output -raw db_username)
# DB_NAME=$(terraform output -raw db_name)

# # For debugging
# echo "RDS Endpoint: $RDS_ENDPOINT"
# echo "ECR Repository URL: $ECR_REPO_URL"

# # Move to the server directory
# cd ../server

# # Update .env file
# if [ -f .env ]; then
#     echo "Updating .env file..."
#     sed -i "s|^DATABASE_URI=.*|DATABASE_URI=mysql+mysqlconnector://$DB_USERNAME:flaskpassword123!@$RDS_ENDPOINT/$DB_NAME|" .env
# else
#     echo ".env file not found. Creating it..."
#     echo "DATABASE_URI=mysql+mysqlconnector://$DB_USERNAME:flaskpassword123!@$RDS_ENDPOINT/$DB_NAME" > .env
# fi

# # Define image name and tag
# IMAGE_NAME="flask-todo-app"
# IMAGE_TAG="latest"
# FULL_IMAGE_NAME="$ECR_REPO_URL:$IMAGE_TAG"

# # Alternative login method
# echo "Logging in to ECR..."
# TOKEN=$(aws ecr get-authorization-token --region $AWS_REGION --output text --query 'authorizationData[].authorizationToken')
# echo $TOKEN | base64 -d | cut -d: -f2 | docker login --username AWS --password-stdin $ECR_REPO_URL

# # Build Docker image
# echo "Building Docker image..."
# docker build -t $IMAGE_NAME:$IMAGE_TAG .

# # Tag the image for ECR
# echo "Tagging Docker image for ECR..."
# docker tag $IMAGE_NAME:$IMAGE_TAG $FULL_IMAGE_NAME

# # Push the image to ECR
# echo "Pushing Docker image to ECR..."
# docker push $FULL_IMAGE_NAME

# # Remove any existing container with same name
# echo "Cleaning up existing containers..."
# docker rm -f flask-todo-server 2>/dev/null || true

# # Pull the image from ECR (to verify it works)
# echo "Pulling Docker image from ECR..."
# docker pull $FULL_IMAGE_NAME

# # Run Docker container with .env file
# echo "Running Docker container from ECR image..."
# docker run -d -p 5000:5000 --env-file .env --name flask-todo-server $FULL_IMAGE_NAME

# echo "Deployment completed successfully!"
# echo "Your Flask Todo App is running at http://localhost:5000"








#!/bin/bash

# Exit immediately if a command fails
set -e

# === Apply Terraform Infrastructure ===
echo "Applying Terraform..."


cd terraform

# cd infra
terraform apply -auto-approve

# Grab the outputs
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)
DB_USERNAME=$(terraform output -raw db_username)
DB_NAME=$(terraform output -raw db_name)
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)

# For debugging
echo "RDS Endpoint: $RDS_ENDPOINT"
echo "ECR Repository URL: $ECR_REPO_URL"
echo "ALB DNS Name: $ALB_DNS_NAME"

# Move to the server directory
cd ../server

# Define image name and tag
IMAGE_NAME="flask-todo-app"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="$ECR_REPO_URL:$IMAGE_TAG"

# Login to ECR - use different methods depending on error
echo "Logging in to ECR..."
# Method 1: Standard method
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL || \
# Method 2: Alternative if Method 1 fails
(echo "Standard login failed, trying alternative method..." && \
 TOKEN=$(aws ecr get-authorization-token --region $AWS_REGION --output text --query 'authorizationData[].authorizationToken') && \
 echo $TOKEN | base64 -d | cut -d: -f2 | docker login --username AWS --password-stdin $ECR_REPO_URL)

# Build Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# Tag the image for ECR
echo "Tagging Docker image for ECR..."
docker tag $IMAGE_NAME:$IMAGE_TAG $FULL_IMAGE_NAME

# Push the image to ECR
echo "Pushing Docker image to ECR..."
docker push $FULL_IMAGE_NAME

# Force new deployment of ECS service
echo "Forcing new deployment of ECS service..."
aws ecs update-service --cluster flask-todo-cluster --service flask-todo-service --force-new-deployment --region $AWS_REGION

echo "Waiting for service to stabilize (this may take a few minutes)..."
aws ecs wait services-stable --cluster flask-todo-cluster --services flask-todo-service --region $AWS_REGION

echo "Deployment completed successfully!"
echo "Your Flask Todo App is now running on ECS Fargate"
echo "You can access it at: http://$ALB_DNS_NAME"