#!/bin/bash

# Build and Push Docker Image to AWS ECR
# This script builds the Docker image and pushes it to Amazon ECR
# Usage: ./build-and-push.sh [AWS_REGION] [ECR_REPO_NAME] [IMAGE_TAG]

set -e  # Exit on error

# Default values
AWS_REGION=${1:-us-east-1}
ECR_REPO_NAME=${2:-simple-webserver}
IMAGE_TAG=${3:-latest}

echo "🐳 Docker Build and Push to ECR Script"
echo "======================================="
echo "AWS Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPO_NAME"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Get AWS Account ID
echo "📋 Retrieving AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS Account ID: $AWS_ACCOUNT_ID"

# Construct ECR Registry URL
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_REPO_URL="$ECR_REGISTRY/$ECR_REPO_NAME"

echo "📋 ECR Repository URL: $ECR_REPO_URL"
echo ""

# Check if ECR repository exists, if not create it
echo "🔍 Checking if ECR repository exists..."
if ! aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION &>/dev/null; then
    echo "📦 Creating ECR repository: $ECR_REPO_NAME"
    aws ecr create-repository \
        --repository-name $ECR_REPO_NAME \
        --region $AWS_REGION
    echo "✓ ECR repository created successfully"
else
    echo "✓ ECR repository already exists"
fi
echo ""

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo "✓ Successfully logged into ECR"
echo ""

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t $ECR_REPO_URL:$IMAGE_TAG .
echo "✓ Docker image built successfully"
echo ""

# Tag as latest
echo "🏷️  Tagging image as latest..."
docker tag $ECR_REPO_URL:$IMAGE_TAG $ECR_REPO_URL:latest
echo "✓ Image tagged as latest"
echo ""

# Push to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_REPO_URL:$IMAGE_TAG
docker push $ECR_REPO_URL:latest
echo "✓ Image pushed to ECR successfully"
echo ""

echo "✅ Build and push completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Update kubernetes/deployment.yaml with the image URI:"
echo "   image: $ECR_REPO_URL:$IMAGE_TAG"
echo ""
echo "2. Deploy to EKS:"
echo "   kubectl apply -f kubernetes/deployment.yaml"
echo "   kubectl apply -f kubernetes/service.yaml"
echo ""
echo "3. Verify deployment:"
echo "   kubectl get pods"
echo "   kubectl get svc simple-webserver-service"