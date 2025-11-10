#!/bin/bash
set -e

SOURCE_IMAGE=$1
TARGET_REPO=$2
TARGET_TAG=$3
AWS_REGION=${4:-us-east-1}
AWS_ACCOUNT_ID=${5:-123456789012}

if [ -z "$SOURCE_IMAGE" ] || [ -z "$TARGET_REPO" ] || [ -z "$TARGET_TAG" ]; then
  echo "Usage: $0 <source_image> <target_repo> <target_tag> [aws_region] [aws_account_id]"
  echo ""
  echo "Example:"
  echo "  $0 my-app:v1.0.0 my-app-staging v1.0.0-rc0"
  exit 1
fi

ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
TARGET_IMAGE="$ECR_REGISTRY/$TARGET_REPO:$TARGET_TAG"

echo "=========================================="
echo "MOCK: Pushing image to ECR"
echo "=========================================="
echo "Source: $SOURCE_IMAGE"
echo "Target: $TARGET_IMAGE"
echo "Region: $AWS_REGION"
echo ""

echo "Step 1: ECR Login"
echo "  Command: aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
echo "  Status: ✓ Logged in"
echo ""

echo "Step 2: Tag image"
echo "  Command: docker tag $SOURCE_IMAGE $TARGET_IMAGE"
echo "  Status: ✓ Tagged"
echo ""

echo "Step 3: Push image"
echo "  Command: docker push $TARGET_IMAGE"
echo "  Progress:"
echo "    - Pushing layer 1/5... 100%"
echo "    - Pushing layer 2/5... 100%"
echo "    - Pushing layer 3/5... 100%"
echo "    - Pushing layer 4/5... 100%"
echo "    - Pushing layer 5/5... 100%"
echo "  Status: ✓ Pushed"
echo ""

echo "=========================================="
echo "✓ Successfully pushed to ECR!"
echo "=========================================="
echo "Repository: $TARGET_REPO"
echo "Tag: $TARGET_TAG"
echo "Digest: sha256:abc123def456... (mocked)"
echo "Image URI: $TARGET_IMAGE"
