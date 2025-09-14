#!/bin/bash
BADGETIZR_VERSION="1.5.5"

show_help() {
    cat <<EOF
Usage: $0 [options]

Options :
  -c <file>, 
  --configuration=<file>,
  --configuration <file>        (Optional) Specify the path to the configuration. Default is .badgetizr.yml

  --pr-id=<id>,
  --pr-id <id>                  (Mandatory) Specify the pull request id.

  --pr-destination-branch=<branch>,
  --pr-destination-branch <branch>        (Mandatory when branch badge is enabled) Specify the pull request destination branch.

  --pr-build-number=<number>,
  --pr-build-number <number>        (Mandatory when CI badge is enabled) Specify the pull request build number.

  --pr-build-url=<url>,
  --pr-build-url <url>              (Mandatory when CI badge is enabled) Specify the pull request build url.

  --version, -v                 Display the version of Badgetizr.
  -h, --help                    Display this help.

EOF
}

# Add label to pull request
# $1 = name of label
# $2 = color of the label
add_label_to_pull_request() {
      local label_name="$1"
      local label_color="$2"

      if [[ -z "$label_name" || "$label_name" == "null" ]]; then
          return 0
      fi

      echo "🏷️  Adding pull request label: $label_name"

      if gh pr edit "$ci_badge_pull_request_id" --add-label "$label_name" 2>/dev/null; then
          echo "✅ Label '$label_name' added successfully"
      else
          echo "⚠️  Label '$label_name' doesn't exist, creating it..."

          # Mapping color to hex
          local hex_color
          case "$label_color" in
              "yellow") hex_color="fbca04" ;;
              "orange") hex_color="d93f0b" ;;
              "red") hex_color="d73a49" ;;
              "green"|"forestgreen") hex_color="28a745" ;;
              "blue") hex_color="0366d6" ;;
              "purple") hex_color="6f42c1" ;;
              "grey"|"gray") hex_color="586069" ;;
              "black") hex_color="24292e" ;;
              *) hex_color="fbca04" ;;
          esac

          if gh label create "$label_name" --color "$hex_color" --description "Auto-created by Badgetizr" 2>/dev/null; then
              echo "✅ Label '$label_name' created successfully"
              if gh pr edit "$ci_badge_pull_request_id" --add-label "$label_name" 2>/dev/null; then
                  echo "✅ Label '$label_name' added to PR"
              fi
          else
              echo "❌ Failed to create label '$label_name'. This should not happen."
          fi
      fi
  }

# Remove the label of a pull request
remove_label_from_pull_request() {
  local label_name="$1"

  if [[ -z "$label_name" || "$label_name" == "null" ]]; then
      return 0
  fi

  echo "🏷️  Removing GitHub label: $label_name"

  if gh pr edit "$ci_badge_pull_request_id" --remove-label "$label_name" 2>/dev/null; then
      echo "✅ Label '$label_name' removed successfully"
  else
      echo "ℹ️  Label '$label_name' was not present on this PR"
  fi
}


