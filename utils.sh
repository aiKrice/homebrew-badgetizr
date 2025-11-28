#!/bin/bash
BADGETIZR_VERSION="3.0.2"

# URL encode a string for shields.io badge API
# Shields.io requires special escaping:
# - Underscore (_) must be doubled (__) to display a literal underscore
# - Dash (-) must be doubled (--) to display a literal dash
# - Other special characters follow standard URL encoding
# See: https://shields.io/badges/static-badge
url_encode_shields() {
    local string="$1"
    # Double dashes and underscores for shields.io, then apply URL encoding
    s="${string}" yq -n -oy eval 'strenv(s) | sub("-"; "--") | sub("_"; "__") | @uri | sub("\\+"; "%20")'
}

show_help() {
    cat <<EOF
Usage: $0 [options]

Options :
  -c <file>,
  --configuration=<file>,
  --configuration <file>        (Optional) Specify the path to the configuration. Default is .badgetizr.yml

  --pr-id=<id>,
  --pr-id <id>                  (Mandatory) Specify the pull/merge request id.

  --pr-destination-branch=<branch>,
  --pr-destination-branch <branch>        (Mandatory when branch badge is enabled) Specify the pull request destination branch.

  --pr-build-number=<number>,
  --pr-build-number <number>        (Mandatory when CI badge is enabled) Specify the pull request build number.

  --pr-build-url=<url>,
  --pr-build-url <url>              (Mandatory when CI badge is enabled) Specify the pull request build url.

  --provider=<provider>,
  --provider <provider>             (Optional) Force provider (github, gitlab). Auto-detected if not specified.

  --version, -v                 Display the version of Badgetizr.
  -h, --help                    Display this help.

EOF
}


