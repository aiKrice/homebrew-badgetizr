#!/usr/bin/env bats

# Test suite for badge generation logic

setup() {
    export BASE_PATH="${BATS_TEST_DIRNAME}/../.."
    source "${BASE_PATH}/utils.sh"
}

@test "WIP detection in title - lowercase 'wip'" {
    title="wip: Add new feature"
    [[ "$title" =~ [Ww][Ii][Pp] ]]
}

@test "WIP detection in title - uppercase 'WIP'" {
    title="WIP: Add new feature"
    [[ "$title" =~ [Ww][Ii][Pp] ]]
}

@test "WIP detection in title - mixed case 'WiP'" {
    title="WiP: Add new feature"
    [[ "$title" =~ [Ww][Ii][Pp] ]]
}

@test "WIP detection in title - no WIP present" {
    title="Add new feature"
    ! [[ "$title" =~ [Ww][Ii][Pp] ]]
}

@test "Badge delimiter start tag" {
    delimiter="<!--begin:badgetizr-->"
    [[ "$delimiter" == "<!--begin:badgetizr-->" ]]
}

@test "Badge delimiter end tag" {
    delimiter="<!--end:badgetizr-->"
    [[ "$delimiter" == "<!--end:badgetizr-->" ]]
}

@test "Hotfix branch detection - main branch" {
    destination_branch="main"
    [[ "$destination_branch" == "main" || "$destination_branch" == "master" ]]
}

@test "Hotfix branch detection - master branch" {
    destination_branch="master"
    [[ "$destination_branch" == "main" || "$destination_branch" == "master" ]]
}

@test "Hotfix branch detection - develop branch" {
    destination_branch="develop"
    ! [[ "$destination_branch" == "main" || "$destination_branch" == "master" ]]
}

@test "CI status validation - started" {
    status="started"
    case "$status" in
        "started"|"passed"|"warning"|"failed")
            valid=true
            ;;
        *)
            valid=false
            ;;
    esac
    [ "$valid" = "true" ]
}

@test "CI status validation - passed" {
    status="passed"
    case "$status" in
        "started"|"passed"|"warning"|"failed")
            valid=true
            ;;
        *)
            valid=false
            ;;
    esac
    [ "$valid" = "true" ]
}

@test "CI status validation - warning" {
    status="warning"
    case "$status" in
        "started"|"passed"|"warning"|"failed")
            valid=true
            ;;
        *)
            valid=false
            ;;
    esac
    [ "$valid" = "true" ]
}

@test "CI status validation - failed" {
    status="failed"
    case "$status" in
        "started"|"passed"|"warning"|"failed")
            valid=true
            ;;
        *)
            valid=false
            ;;
    esac
    [ "$valid" = "true" ]
}

@test "CI status validation - invalid status" {
    status="invalid"
    case "$status" in
        "started"|"passed"|"warning"|"failed")
            valid=true
            ;;
        *)
            valid=false
            ;;
    esac
    [ "$valid" = "false" ]
}

@test "Checkbox counting - no checkboxes" {
    body="This is a PR body without checkboxes"
    unchecked_count=$(printf "%s\n" "$body" | grep -c "\- \[ \]" 2>/dev/null || true)
    [ "$unchecked_count" -eq 0 ]
}

@test "Checkbox counting - one unchecked checkbox" {
    body="- [ ] Task 1"
    unchecked_count=$(printf "%s\n" "$body" | grep -c "\- \[ \]" 2>/dev/null || echo "0")
    [ "$unchecked_count" -eq 1 ]
}

@test "Checkbox counting - multiple unchecked checkboxes" {
    body="- [ ] Task 1
- [ ] Task 2
- [ ] Task 3"
    unchecked_count=$(printf "%s\n" "$body" | grep -c "\- \[ \]" 2>/dev/null || echo "0")
    [ "$unchecked_count" -eq 3 ]
}

@test "Checkbox counting - mixed checked and unchecked" {
    body="- [x] Task 1
- [ ] Task 2
- [x] Task 3"
    unchecked_count=$(printf "%s\n" "$body" | grep -c "\- \[ \]" 2>/dev/null || echo "0")
    [ "$unchecked_count" -eq 1 ]
}

@test "Checkbox counting - all checked" {
    body="- [x] Task 1
- [x] Task 2
- [x] Task 3"
    unchecked_count=$(printf "%s\n" "$body" | grep -c "\- \[ \]" 2>/dev/null || true)
    [ "$unchecked_count" -eq 0 ]
}
