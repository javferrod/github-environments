# GitHub Environments Deployment Prototype

This repository demonstrates a sophisticated deployment pipeline using GitHub Environments and ECR for progressive environment promotion.

## Overview

This prototype implements a three-tier deployment system:

1. **Staging** - First deployment target with RC (Release Candidate) versioning
2. **Goldenmaster** - Pre-production validation environment
3. **Production** - Final production deployment with stable versioning

## Architecture

### ECR Repository Structure

The system uses **separate ECR repositories** per environment:

- `my-app-staging` - Staging environment images
- `my-app-goldenmaster` - Goldenmaster environment images
- `my-app-production` - Production environment images
- `my-app-builds` - Temporary build artifacts (from master merges)

### Versioning Strategy

- **Build on master**: Creates base version from git tags (e.g., `v1.0.0`)
- **Staging deployment**: Adds RC suffix with auto-incrementing number (e.g., `v1.0.0-rc0`, `v1.0.0-rc1`)
- **Goldenmaster deployment**: Preserves RC number from staging (e.g., `v1.0.0-rc1`)
- **Production deployment**: Removes RC suffix for stable release (e.g., `v1.0.0`)

### RC Number Management

Each environment tracks its own RC numbers:

- **Staging**: Queries existing tags in `my-app-staging` ECR, finds highest RC number for the version, and increments
- **Goldenmaster**: Uses the same RC number as staging (promotes the exact version)
- **Production**: Strips RC suffix and tags `v1.0.0` in all three ECRs

## Workflow Files

### 1. Build Workflow (`.github/workflows/build.yml`)

**Trigger**: Automatic on push to `master` or `main` branch

**What it does**:
- Detects or creates version from git tags
- Mocks Docker image build
- Mocks push to temporary ECR location (`my-app-builds`)
- Outputs version number for deployment workflow

**Usage**: Automatically runs on merge to master

### 2. Deploy Workflow (`.github/workflows/deploy.yml`)

**Trigger**: Manual via GitHub Actions UI (`workflow_dispatch`)

**Input**: Version number (e.g., `v1.0.0`)

**Jobs**:

#### Job 1: Deploy to Staging
- **Environment**: `staging` (requires approval)
- Calculates next RC number by querying staging ECR
- Tags image as `{version}-rc{X}` in `my-app-staging` ECR
- Deploys to staging environment
- Outputs: `staged_version` (e.g., `v1.0.0-rc2`)

#### Job 2: Deploy to Goldenmaster
- **Depends on**: Job 1 (staging)
- **Environment**: `goldenmaster` (requires approval)
- Uses RC number from staging (preserves `v1.0.0-rc2`)
- Tags same version in `my-app-goldenmaster` ECR
- Deploys to goldenmaster environment

#### Job 3: Deploy to Production
- **Depends on**: Job 1 & 2 (staging & goldenmaster)
- **Environment**: `production` (requires approval)
- Removes RC suffix from version
- Tags final version (e.g., `v1.0.0`) in ALL three ECRs:
  - `my-app-staging:v1.0.0`
  - `my-app-goldenmaster:v1.0.0`
  - `my-app-production:v1.0.0`
- Deploys to production environment
- Creates GitHub release

## How to Use

### Initial Setup

1. **Configure GitHub Environments**:
   - Go to Repository Settings → Environments
   - Create three environments: `staging`, `goldenmaster`, `production`
   - Add required reviewers to each environment for approvals

2. **Create Git Tag** (if none exists):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### Deployment Flow

#### Step 1: Build on Master

1. Merge code to `master` branch
2. Build workflow runs automatically
3. Note the version number in the workflow summary

#### Step 2: Deploy to Staging

1. Go to **Actions** → **Deploy** workflow
2. Click **Run workflow**
3. Enter the version (e.g., `v1.0.0`)
4. Click **Run workflow**
5. Approve the **staging** environment deployment
6. Wait for staging deployment to complete
7. Version will be tagged as `v1.0.0-rc0` (or next available RC)

#### Step 3: Promote to Goldenmaster

1. The workflow automatically continues (after staging completes)
2. Approve the **goldenmaster** environment deployment
3. Wait for goldenmaster deployment to complete
4. Same version (`v1.0.0-rc0`) is now in goldenmaster

#### Step 4: Release to Production

1. The workflow automatically continues (after goldenmaster completes)
2. Approve the **production** environment deployment
3. Wait for production deployment to complete
4. Version `v1.0.0` (without RC) is tagged in all ECRs and deployed

### Example Scenario

**Scenario**: You merge a fix to master, then deploy through all environments.

1. Merge to master → Build runs → Version: `v1.0.0`
2. Run deploy workflow with `v1.0.0`
3. Approve staging → Deployed as `v1.0.0-rc0`
4. Approve goldenmaster → Deployed as `v1.0.0-rc0`
5. Approve production → Deployed as `v1.0.0`

**Scenario**: You merge another fix before deploying the first one (hotfix scenario).

1. Merge to master → Build runs → Version: `v1.0.0` (same version)
2. Run deploy workflow with `v1.0.0`
3. Approve staging → Deployed as `v1.0.0-rc1` (RC incremented!)
4. Approve goldenmaster → Deployed as `v1.0.0-rc1`
5. Approve production → Deployed as `v1.0.0`

## Mock Scripts

The `.github/scripts/` directory contains mock implementations:

- **`mock-build.sh`** - Simulates Docker build
- **`mock-ecr-push.sh`** - Simulates ECR push and tagging
- **`mock-deploy.sh`** - Simulates ECS deployment
- **`get-next-rc.sh`** - Calculates next RC number for a version

These can be run locally for testing:

```bash
# Calculate next RC for version
.github/scripts/get-next-rc.sh v1.0.0 my-app-staging

# Mock build
.github/scripts/mock-build.sh v1.0.0 abc123

# Mock ECR push
.github/scripts/mock-ecr-push.sh my-app:v1.0.0 my-app-staging v1.0.0-rc0

# Mock deployment
.github/scripts/mock-deploy.sh staging v1.0.0-rc0 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app-staging:v1.0.0-rc0
```

## Benefits of This Approach

1. **Single Workflow View**: The entire promotion flow (staging → goldenmaster → production) is visible in one workflow run
2. **Progressive Approvals**: Each environment requires explicit approval before deployment
3. **Automatic RC Management**: RC numbers auto-increment when multiple changes target the same version
4. **Immutable Promotion**: The exact same image progresses through environments
5. **Production Stability**: Production releases have clean version tags without RC suffixes
6. **Audit Trail**: Complete deployment history is tracked in the single workflow

## Real Implementation

To convert this prototype to a real deployment:

1. Replace mock scripts with actual AWS CLI commands
2. Configure AWS credentials in GitHub secrets
3. Update ECR repository names and AWS account IDs
4. Add actual application Dockerfile
5. Configure ECS task definitions and services
6. Add health checks and smoke tests
7. Implement actual version tagging logic
8. Set up monitoring and rollback procedures

## GitHub Environments Configuration

Required environment settings:

- **staging**: Add reviewers if desired (optional for dev testing)
- **goldenmaster**: Add required reviewers (recommended)
- **production**: Add multiple required reviewers (mandatory for safety)

## Notes

- This is a **prototype** - all build, push, and deploy operations are mocked
- RC numbers increment independently per version (v1.0.0-rc0, v1.0.0-rc1, v1.1.0-rc0)
- The system supports multiple deployments of the same version (useful for hotfixes)
- Production tagging ensures all ECRs have the same stable version reference
