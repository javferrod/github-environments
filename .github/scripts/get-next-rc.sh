#!/bin/bash
set -e

VERSION=$1
ECR_REPO=$2
AWS_REGION=${3:-us-east-1}

if [ -z "$VERSION" ] || [ -z "$ECR_REPO" ]; then
  echo "Usage: $0 <version> <ecr_repo> [aws_region]"
  echo ""
  echo "Example:"
  echo "  $0 v1.0.0 my-app-staging"
  echo ""
  echo "This script calculates the next RC number for a given version by:"
  echo "1. Querying ECR for existing tags matching the version pattern"
  echo "2. Finding the highest RC number"
  echo "3. Incrementing it by 1"
  exit 1
fi

echo "=========================================="
echo "Calculating next RC number"
echo "=========================================="
echo "Version: $VERSION"
echo "ECR Repository: $ECR_REPO"
echo "Region: $AWS_REGION"
echo ""

echo "Step 1: Query ECR for existing tags"
echo "  Command: aws ecr describe-images \\"
echo "    --repository-name $ECR_REPO \\"
echo "    --region $AWS_REGION \\"
echo "    --query 'imageDetails[*].imageTags[*]' \\"
echo "    --output json"
echo ""

# Mock: Simulate ECR response with existing tags
echo "  MOCK Response:"
EXISTING_TAGS=(
  "$VERSION-rc0"
  "$VERSION-rc1"
  "$VERSION-rc2"
  "v0.9.0-rc0"
  "v0.9.0-rc1"
)

for tag in "${EXISTING_TAGS[@]}"; do
  echo "    - $tag"
done
echo ""

echo "Step 2: Filter tags for version $VERSION"
MATCHING_TAGS=()
for tag in "${EXISTING_TAGS[@]}"; do
  if [[ "$tag" == "$VERSION-rc"* ]]; then
    MATCHING_TAGS+=("$tag")
    echo "    ✓ $tag (matches)"
  fi
done
echo ""

echo "Step 3: Find highest RC number"
HIGHEST_RC=-1
for tag in "${MATCHING_TAGS[@]}"; do
  RC_NUM=$(echo "$tag" | grep -oP 'rc\K\d+' || echo "-1")
  echo "    Tag: $tag -> RC: $RC_NUM"
  if [ "$RC_NUM" -gt "$HIGHEST_RC" ]; then
    HIGHEST_RC=$RC_NUM
  fi
done
echo ""
echo "  Highest RC found: $HIGHEST_RC"
echo ""

echo "Step 4: Calculate next RC"
NEXT_RC=$((HIGHEST_RC + 1))
NEXT_VERSION="$VERSION-rc$NEXT_RC"
echo "  Next RC number: $NEXT_RC"
echo "  Next version: $NEXT_VERSION"
echo ""

echo "=========================================="
echo "✓ Calculation complete"
echo "=========================================="
echo "Next version to use: $NEXT_VERSION"
echo ""

# Output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "next_rc=$NEXT_RC" >> "$GITHUB_OUTPUT"
  echo "next_version=$NEXT_VERSION" >> "$GITHUB_OUTPUT"
fi

# Output for script usage
echo "$NEXT_VERSION"
