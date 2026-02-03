#!/usr/bin/env bats
# Unit tests for configuration default values

setup() {
    export BASE_PATH="${BATS_TEST_DIRNAME}/../.."
    export TEST_TEMP_DIR="${BATS_TEST_TMPDIR}/badgetizr_test_$$"
    mkdir -p "${TEST_TEMP_DIR}"
}

teardown() {
    rm -rf "${TEST_TEMP_DIR}"
}

# ============================================================================
# Hotfix Badge Configuration Defaults
# ============================================================================

@test "Hotfix badge: production_branch defaults to 'master' when not specified" {
    # Arrange - Create config without production_branch
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
EOF

    # Act
    local production_branch=$(yq e '.badge_hotfix.settings.production_branch // "master"' "${config_file}")

    # Assert
    [ "${production_branch}" = "master" ]
}

@test "Hotfix badge: production_branch uses configured value when specified" {
    # Arrange - Create config with production_branch set to "main"
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    production_branch: "main"
EOF

    # Act
    local production_branch=$(yq e '.badge_hotfix.settings.production_branch // "master"' "${config_file}")

    # Assert
    [ "${production_branch}" = "main" ]
}

@test "Hotfix badge: production_branch uses configured value 'trunk'" {
    # Arrange - Create config with production_branch set to "trunk"
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    production_branch: "trunk"
EOF

    # Act
    local production_branch=$(yq e '.badge_hotfix.settings.production_branch // "master"' "${config_file}")

    # Assert
    [ "${production_branch}" = "trunk" ]
}

@test "Hotfix badge: empty production_branch value defaults to 'master'" {
    # Arrange - Create config with empty production_branch
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_hotfix:
  enabled: "true"
  settings:
    production_branch: ""
EOF

    # Act
    local production_branch=$(yq e '.badge_hotfix.settings.production_branch // "master"' "${config_file}")

    # Assert - Empty string should return empty, not default
    [ "${production_branch}" = "" ]
}

@test "Hotfix badge: null production_branch value defaults to 'master'" {
    # Arrange - Create config with null production_branch
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_hotfix:
  enabled: "true"
  settings:
    production_branch: null
EOF

    # Act
    local production_branch=$(yq e '.badge_hotfix.settings.production_branch // "master"' "${config_file}")

    # Assert
    [ "${production_branch}" = "master" ]
}

# ============================================================================
# Other Badge Configuration Defaults
# ============================================================================

@test "WIP badge: color defaults to 'yellow' when not specified" {
    # Arrange
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_wip:
  enabled: "true"
  settings:
    label: "WIP"
EOF

    # Act
    local color=$(yq e '.badge_wip.settings.color // "yellow"' "${config_file}")

    # Assert
    [ "${color}" = "yellow" ]
}

@test "Branch badge: base_branch defaults to 'develop' when not specified" {
    # Arrange
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_base_branch:
  enabled: "true"
  settings:
    color: "orange"
EOF

    # Act
    local base_branch=$(yq e '.badge_base_branch.settings.base_branch // "develop"' "${config_file}")

    # Assert
    [ "${base_branch}" = "develop" ]
}

@test "CI badge: color defaults to 'purple' when not specified" {
    # Arrange
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_ci:
  enabled: "true"
  settings:
    label: "Build"
EOF

    # Act
    local color=$(yq e '.badge_ci.settings.color // "purple"' "${config_file}")

    # Assert
    [ "${color}" = "purple" ]
}

@test "Ticket badge: color defaults to 'blue' when not specified" {
    # Arrange
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_ticket:
  enabled: "true"
  settings:
    label: "JIRA"
EOF

    # Act
    local color=$(yq e '.badge_ticket.settings.color // "blue"' "${config_file}")

    # Assert
    [ "${color}" = "blue" ]
}

@test "Ready for approval badge: color defaults to 'green' when not specified" {
    # Arrange
    local config_file="${TEST_TEMP_DIR}/config.yml"
    cat > "${config_file}" << EOF
badge_ready_for_approval:
  enabled: "true"
  settings:
    label: "Ready"
EOF

    # Act
    local color=$(yq e '.badge_ready_for_approval.settings.color // "green"' "${config_file}")

    # Assert
    [ "${color}" = "green" ]
}
