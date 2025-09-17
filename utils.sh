#!/bin/bash
BADGETIZR_VERSION="2.0.0"

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


