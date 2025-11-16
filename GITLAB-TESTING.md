<h1 align="center">
    <img src="logo.png" alt="Badgetizr Logo" width="120"/>
    <br/>
    Testing Badgetizr on GitLab
</h1>

<p align="center">
    This guide explains how to test Badgetizr on GitLab using GitLab CI/CD pipelines.
</p>

## Prerequisites

1. **GitLab Project**: You need a GitLab repository where you can create merge requests (GitLab.com or self-managed)
2. **GitLab Access Token**: A personal access token with `api` scope to interact with merge requests
3. **Project Variables**: Configure `GITLAB_ACCESS_TOKEN` in your GitLab project settings
4. **Self-Managed Only**: If using self-managed GitLab, you'll need to configure `GITLAB_HOST`

## Setup Instructions

### 1. Configure GitLab Access Token

1. Go to **GitLab** → **Settings** → **Access Tokens**
2. Create a new token with `api` scope
3. In your GitLab project, go to **Settings** → **CI/CD** → **Variables**
4. Add a new variable:
   - **Key**: `GITLAB_ACCESS_TOKEN`
   - **Value**: Your personal access token
   - **Protected**: ❌ (must be unchecked to work with merge request pipelines)
   - **Masked**: ✅ (recommended for security)

> **⚠️ Important**: The `Protected` option **must be disabled** for the token to work properly with merge request pipelines. Protected variables are only available to protected branches, but merge request pipelines run in a different context.

### 2. Create `.gitlab-ci.yml`

Create a `.gitlab-ci.yml` file in your repository root with the following content:

> **⚠️ Important**: Replace `{BRANCH}` with the actual GitHub branch you want to test (e.g., `feat/GH-4_implement_build_status_badges`, `master`, `develop`, etc.)

**Universal configuration (works for both GitLab.com and self-managed):**

```yaml
badgetizr:
  stage: build
  image: alpine:latest
  variables:
    GLAB_VERSION: "1.72.0"
    BRANCH: "{BRANCH}"  # Replace with: master, develop, feat/your-feature, etc.
    # Auto-detects: gitlab.com for SaaS, your instance for self-managed
    GITLAB_HOST: "${CI_SERVER_HOST}"
    BUILD_URL: "https://${CI_SERVER_HOST}/${CI_PROJECT_PATH}/-/pipelines/${CI_PIPELINE_ID}"
    CONFIG_PATH: "../.badgetizr.yml"  # Relative or absolute path (default: .badgetizr.yml if not specified)
    GITLAB_TOKEN: $GITLAB_ACCESS_TOKEN
  before_script:
    - apk add --no-cache curl bash yq
    - curl -sSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp
    - mv /tmp/bin/glab /usr/local/bin/glab && chmod +x /usr/local/bin/glab
    - curl -sSL https://github.com/aiKrice/homebrew-badgetizr/archive/refs/heads/${BRANCH}.tar.gz | tar -xz
    - cd homebrew-badgetizr-*
    - export GITLAB_HOST="${CI_SERVER_HOST}"
  script:
    # Started status
    - |
      ./badgetizr -c ${CONFIG_PATH} \
      --pr-id=$CI_MERGE_REQUEST_IID \
      --pr-destination-branch=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME \
      --pr-build-number=$CI_PIPELINE_ID \
      --pr-build-url="${BUILD_URL}" \
      --ci-status=started \
      --ci-text="Running Badgetizr" \
      --provider=gitlab

    # Wait to see the started badge
    - sleep 5

    # Success status
    - |
      ./badgetizr -c ${CONFIG_PATH} \
      --pr-id=$CI_MERGE_REQUEST_IID \
      --pr-destination-branch=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME \
      --pr-build-number=$CI_PIPELINE_ID \
      --pr-build-url="${BUILD_URL}" \
      --ci-status=passed \
      --provider=gitlab
  after_script:
    # Failed status (runs only on failure)
    - |
      if [ "$CI_JOB_STATUS" = "failed" ]; then
        cd homebrew-badgetizr-*
        ./badgetizr -c ${CONFIG_PATH} \
        --pr-id=$CI_MERGE_REQUEST_IID \
        --pr-destination-branch=$CI_MERGE_REQUEST_TARGET_BRANCH_NAME \
        --pr-build-number=$CI_PIPELINE_ID \
        --pr-build-url="${BUILD_URL}" \
        --ci-status=failed \
        --provider=gitlab
      fi
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

**Key features:**
- ✅ **Universal**: Works for GitLab.com and self-managed instances automatically
- ✅ **Centralized variables**: Easy to update versions, branch, and paths
- ✅ **Auto-detection**: `CI_SERVER_HOST` adapts to your environment (`gitlab.com` or your instance)
- ✅ **CI status progression**: Shows `started` → `passed` or `failed` badges

**Customization options:**
- **Custom ports**: Modify `BUILD_URL` with `$CI_SERVER_PORT` if needed
- **Different config**: Change `CONFIG_PATH` to use a different config location (accepts relative or absolute paths, defaults to `.badgetizr.yml` if not specified)
- **Branch version**: Update `BRANCH` variable to test different Badgetizr versions

### 3. Create Configuration File

Create a `.badgetizr.yml` file in your repository root:

```yaml
badge_ci:
  enabled: "true"
  settings:
    label_color: "black"
    label: "Build"
    logo: "gitlab"
    color: "darkgreen"

badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    logo: "vlcmediaplayer"

badge_ready_for_approval:
  enabled: "true"
  settings:
    color: "darkgreen"
    label: "Ready"
    logo: "checkmark"
```

## Testing Process

### 1. Create a Merge Request

1. Create a new branch in your GitLab repository
2. Make some changes and push the branch
3. Create a merge request targeting your master branch

### 2. Watch the Pipeline

1. Go to **CI/CD** → **Pipelines** in your GitLab project
2. You should see a pipeline running for your merge request
3. The pipeline will execute the Badgetizr job

### 3. Observe Badge Updates

You should see the badges update in real-time on your merge request:

1. **Started**: ![Badge](https://img.shields.io/badge/Running_Badgetizr-ignored?label=Build&color=yellow&logo=gitlab)
2. **Success**: ![Badge](https://img.shields.io/badge/12345-ignored?label=Build&color=darkgreen&logo=gitlab)

### 4. Test Different Scenarios

#### Test CI Status Progression
The pipeline will show:
1. Yellow badge with "Running Badgetizr" text (for 5 seconds)
2. Green badge with pipeline ID number

#### Test Failure Scenario
To test the failure scenario, you can temporarily modify the pipeline to force a failure:

```yaml
# Add this line in the script section to test failure
- exit 1  # This will cause the job to fail
```

## Branch Examples

Common branches you might want to test:

- **Latest stable**: `master`
- **Development**: `develop`
- **Feature branch**: `feat/GH-4_implement_build_status_badges`
- **Specific version**: `v1.5.4`

## Expected Results

When everything works correctly, you should see:

1. **Pipeline runs** only on merge request events
2. **Badges appear** in the merge request description
3. **Status progression** from "started" → "passed"
4. **Clickable badges** that link to the pipeline

## Troubleshooting

### Pipeline doesn't run
- Check that you're creating a **merge request** (not just pushing to a branch)
- Verify the `rules` section in your `.gitlab-ci.yml`

### Badges don't appear
- Verify your `GITLAB_ACCESS_TOKEN` is correctly configured
- **Check that the variable is NOT protected** (Protected: ❌)
- Check the pipeline logs for authentication errors
- Ensure the token has `api` scope
- Common error: `401 Unauthorized` usually means the token is protected or invalid

### Self-Managed GitLab Issues

#### Authentication fails for self-managed instance
- Ensure `GITLAB_HOST` is set correctly (e.g., `export GITLAB_HOST=$CI_SERVER_HOST`)
- Check that your `GITLAB_TOKEN` has the correct permissions
- Verify your GitLab instance is accessible from the runner
- Test authentication manually: `curl -H "Authorization: Bearer $GITLAB_TOKEN" https://your-gitlab-host/api/v4/user`

#### Config file not found
- Use `../.badgetizr.yml` (relative to the extracted archive directory)
- The path must be relative to where `cd homebrew-badgetizr-*` changes to

#### Build URLs don't work
- Use `$CI_SERVER_HOST` instead of hardcoded hostnames
- For custom ports: use `$CI_SERVER_URL` or construct with `$CI_SERVER_PORT`
- Example: `https://$CI_SERVER_HOST:8443/$CI_PROJECT_PATH/-/pipelines/$CI_PIPELINE_ID`

#### Firewall/Network issues
If using self-managed GitLab with strict firewall rules, ensure these domains are allowed:
- `gitlab.com` (for downloading glab CLI)
- `github.com` (for downloading badgetizr)
- `objects.githubusercontent.com` (for GitHub redirects)

### Wrong branch downloaded
- Double-check you replaced `{BRANCH}` with the actual branch name
- Verify the branch exists on GitHub

### Dependencies fail to install
- Check your internet connectivity in the GitLab runner
- Verify the package URLs are accessible

## Cleanup

After testing, you can:
1. Remove the `.gitlab-ci.yml` file if not needed for production
2. Keep the `.badgetizr.yml` for future use
3. Revoke the access token if no longer needed

## Next Steps

Once testing is successful on GitLab, you can:
- Adapt the configuration for your production workflows
- Customize badge settings for your team's needs
- Integrate with your existing GitLab CI/CD pipelines