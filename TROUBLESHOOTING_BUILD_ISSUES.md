# GitHub Actions Build Troubleshooting Guide

## Current Issue: Git Authentication Failure

The build is failing with error: `The process '/usr/bin/git' failed with exit code 128`

### Root Cause Analysis
This error typically occurs due to:
1. **Git authentication issues** - The workflow doesn't have proper access to the repository
2. **Repository permissions** - The GitHub token doesn't have sufficient permissions
3. **Git configuration** - Missing Git user configuration in the workflow

### Solutions Implemented

#### 1. Updated Main Workflow (.github/workflows/build.yml)
- Added explicit token configuration: `token: ${{ secrets.GITHUB_TOKEN }}`
- Added `fetch-depth: 0` for full repository history
- Improved error handling

#### 2. Created Simple Workflow (.github/workflows/simple-build.yml)
- Minimal configuration for basic APK building
- Removed complex dependencies
- Focus on core Flutter build process

#### 3. Created Robust Workflow (.github/workflows/robust-build.yml)
- Added explicit Git configuration
- Better error handling
- Comprehensive setup steps

### Manual Testing Steps

#### Test Local Build
```bash
# Navigate to project directory
cd dental_case_app

# Clean and get dependencies
flutter clean
flutter pub get

# Test build locally
flutter build apk --debug
```

#### Test Workflow Manually
1. Go to GitHub repository
2. Navigate to Actions tab
3. Select "Robust APK Build" workflow
4. Click "Run workflow" button
5. Select main branch
6. Click "Run workflow"

### Alternative Solutions

#### Option 1: Use Personal Access Token
1. Create a Personal Access Token (PAT) with repo permissions
2. Add it as a repository secret named `PAT_TOKEN`
3. Update workflow to use: `token: ${{ secrets.PAT_TOKEN }}`

#### Option 2: Disable Workflow on Push
1. Remove `push` trigger from workflow
2. Only use `workflow_dispatch` for manual builds
3. This prevents automatic builds that might fail

#### Option 3: Use Different Runner
1. Change from `ubuntu-latest` to `windows-latest`
2. This might resolve Git-related issues on different OS

### Current Workflow Files

1. **build.yml** - Main workflow with token configuration
2. **simple-build.yml** - Minimal workflow for basic builds
3. **robust-build.yml** - Comprehensive workflow with Git configuration

### Next Steps

1. **Commit and push** the updated workflow files
2. **Test the robust-build.yml** workflow manually
3. **Monitor the build logs** for specific error messages
4. **If still failing**, try the alternative solutions above

### Debugging Commands

```bash
# Check Git status
git status

# Check Git configuration
git config --list

# Check Flutter version
flutter --version

# Check Flutter doctor
flutter doctor -v

# Test Android build
flutter build apk --debug --verbose
```

### Repository Health Check

- [ ] Git repository is properly initialized
- [ ] All files are committed and pushed
- [ ] No large files in Git history
- [ ] Repository permissions are correct
- [ ] GitHub Actions are enabled for the repository

### Contact Information

If issues persist, check:
1. GitHub repository settings
2. Actions permissions
3. Repository secrets configuration
4. Branch protection rules 