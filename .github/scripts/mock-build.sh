#!/bin/bash
set -e

VERSION=$1
COMMIT_SHA=$2

if [ -z "$VERSION" ] || [ -z "$COMMIT_SHA" ]; then
  echo "Usage: $0 <version> <commit_sha>"
  exit 1
fi

echo "=========================================="
echo "MOCK: Building Docker image"
echo "=========================================="
echo "Version: $VERSION"
echo "Commit: $COMMIT_SHA"
echo ""
echo "Command would be:"
echo "  docker build -t my-app:$VERSION \\"
echo "    --build-arg VERSION=$VERSION \\"
echo "    --build-arg COMMIT=$COMMIT_SHA \\"
echo "    ."
echo ""
echo "Build steps:"
echo "  [1/5] FROM node:18-alpine"
echo "  [2/5] COPY package*.json ./"
echo "  [3/5] RUN npm ci --production"
echo "  [4/5] COPY . ."
echo "  [5/5] CMD [\"npm\", \"start\"]"
echo ""
echo "✓ Build completed successfully!"
echo ""
echo "Image: my-app:$VERSION"
echo "Size: 125MB (mocked)"
