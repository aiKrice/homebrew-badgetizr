#!/bin/bash

# Read config file
config_file=".badgetizr.yml"
if [ -f "$config_file" ]; then
    wip_badge_enabled=$(yq e '.badge_wip.enabled // "true"' "$config_file")
    wip_badge_label=$(yq e '.badge_wip.settings.label // "Work in Progress"' "$config_file")
    wip_badge_color=$(yq e '.badge_wip.settings.color // "yellow"' "$config_file")
    wip_badge_logo=$(yq e '.badge_wip.settings.logo // "vlcmediaplayer"' "$config_file")

    branch_badge_enabled=$(yq e '.badge_base_branch.enabled // "true"' "$config_file")
    branch_badge_base_branch=$(yq e '.badge_base_branch.settings.base_branch // "develop"' "$config_file")
    branch_badge_color=$(yq e '.badge_base_branch.settings.color // "orange"' "$config_file")
    branch_badge_label=$(yq e '.badge_base_branch.settings.label // "Target branch"' "$config_file")

    ci_badge_enabled=$(yq e '.badge_ci.enabled // "false"' "$config_file")
    ci_badge_color=$(yq e '.badge_ci.settings.color // "purple"' "$config_file")
    ci_badge_label=$(yq e '.badge_ci.settings.label // "CI"' "$config_file")
    ci_badge_logo=$(yq e '.badge_ci.settings.logo // "🤖"' "$config_file")

    ticket_badge_enabled=$(yq e '.badge_ticket.enabled // "false"' "$config_file")
    ticket_badge_pattern=$(yq e '.badge_ticket.settings.sed_pattern // ".*\\(([^)]+)\\).*"' "$config_file")
    ticket_badge_url=$(yq e '.badge_ticket.settings.url // "https://yourproject.atlassian.net/browse/"' "$config_file")
    ticket_badge_color=$(yq e '.badge_ticket.settings.color // "blue"' "$config_file")
    ticket_badge_label=$(yq e '.badge_ticket.settings.label // "Jira"' "$config_file")
    ticket_badge_logo=$(yq e '.badge_ticket.settings.logo // "jirasoftware"' "$config_file")

    dynamic_badge_enabled=$(yq e '.badge_dynamic.enabled // "false"' "$config_file")
else
    echo "🔵 $config_file not found. Using default values."
    wip_badge_enabled="true"
    wip_badge_label="Work in Progress"
    wip_badge_color="yellow"
    wip_badge_logo="vlcmediaplayer"

    branch_badge_enabled="true"
    branch_badge_base_branch="develop"
    branch_badge_color="orange"
    branch_badge_label="Target branch"

    ci_badge_enabled="false"
    ticket_badge_enabled="false"
    dynamic_badge_enabled="false"
fi

pull_request_body=$(gh pr view $BITRISE_PULL_REQUEST --json body -q '.body')
pull_request_title=$(gh pr view $BITRISE_PULL_REQUEST --json title -q '.title')

# Extract current badges from the pull request body
pull_request_body=$(echo "$pull_request_body" | awk '/<!--begin:badgetizr-->/ {flag=1; next} /<!--end:badgetizr-->/ {flag=0; next} !flag' | tr -d '\r')          

all_badges=

#Jira Badge
if [ "$ticket_badge_enabled" = "true" ]; then
    ticket_id=$(echo "$pull_request_title" | sed -n -E "s/${ticket_badge_pattern}/\1/p")
    ticket_badge_url=$(printf "$ticket_badge_url" "$ticket_id")
    if [[ -n "$ticket_id" ]]; then
        echo "🟡 Ticket id identified is -> $ticket_id"
        ticket_id_for_badge=$(echo $ticket_id | sed -E 's/ /_/g; s/-/--/g') 
        ticket_badge="[![Static Badge](https://img.shields.io/badge/$ticket_badge_label-$ticket_id_for_badge-$ticket_badge_color?logo=$ticket_badge_logo&color=$ticket_badge_color&labelColor=grey)]($ticket_badge_url)"
        all_badges=$all_badges$ticket_badge
    fi
fi

# CI Badge
if [ "$ci_badge_enabled" = "true" ]; then
    if [[ -z "$BADGETIZR_BUILD_NUMBER" ]]; then
        echo "🔴 BADGETIZR_BUILD_NUMBER is not defined: You have to export it in the environment."
        exit 1
    fi
    if [[ -z "$BADGETIZR_BUILD_URL" ]]; then
        echo "🔴 BADGETIZR_BUILD_URL is not defined: You have to export it in the environment."
        exit 1
    fi
    ci_badge_build_number=$BADGETIZR_BUILD_NUMBER
    ci_badge_build_url=$BADGETIZR_BUILD_URL

    #Evaluation of the env var defined in the yaml config file
    yq eval '.badge_ci.settings.build_number = env(BADGETIZR_BUILD_NUMBER) | .badge_ci.settings.build_url = env(BADGETIZR_BUILD_URL)' "$config_file" >/dev/null

    ci_badge="[![Static Badge](https://img.shields.io/badge/$ci_badge_label-$ci_badge_build_number-purple?logo=$ci_badge_logo&logoColor=white&labelColor=$ci_badge_color&color=green)]($ci_badge_build_url)"
    all_badges=$(echo $all_badges $ci_badge)
fi

# Target Branch Badge 
if [ "$branch_badge_enabled" = "true" ]; then
    if [[ -z "$BADGETIZR_PR_DESTINATION_BRANCH" ]]; then
        echo "🔴 BADGETIZR_PR_DESTINATION_BRANCH is not defined: You have to export it in the environment."
        exit 1
    fi
    #Evaluation of the env var defined in the yaml config file
    yq eval '.badge_base_branch.settings.destination_pr_branch = env(BADGETIZR_PR_DESTINATION_BRANCH)' "$config_file" >/dev/null
    branch_badge_label_for_badge=$(echo $branch_badge_label | sed -E 's/ /_/g; s/-/--/g')
    if [[ "$BADGETIZR_PR_DESTINATION_BRANCH" != "$branch_badge_base_branch" ]];then
        branch_badge="![Static Badge](https://img.shields.io/badge/$branch_badge_label_for_badge-$BADGETIZR_PR_DESTINATION_BRANCH-$branch_badge_color?labelColor=grey&color=$branch_badge_color)"
        all_badges=$(echo $all_badges $branch_badge)
    fi
fi

# Wip Badge
if [ "$wip_badge_enabled" = "true" ]; then
    if [[ "$pull_request_title" =~ [Ww][Ii][Pp] ]]; then
        wip_badge="![Static Badge](https://img.shields.io/badge/${wip_badge_label}-${wip_badge_color}?logo=$wip_badge_logo&logoColor=white)"
        all_badges=$(echo $all_badges $wip_badge)
    fi
fi

# Dynamic Badge
if [ "$dynamic_badge_enabled" = "true" ]; then
    badge_count=$(yq '.badge_dynamic.settings.patterns | length' "$config_file")

    for ((i=0; i<$badge_count; i++)); do
        pattern=$(yq ".badge_dynamic.settings.patterns[$i].pattern // \"no_pattern\"" "$config_file")
        label=$(yq ".badge_dynamic.settings.patterns[$i].label // \"Badge_$1\"" "$config_file")
        default_label=$(echo $label | sed -E 's/ /_/g; s/-/--/g')
        override_label=$(jq -rn --arg s "$label" '$s | @uri')
        value=$(yq ".badge_dynamic.settings.patterns[$i].value // \"default\"" "$config_file" | sed -E 's/ /_/g; s/-/--/g')
        color=$(yq ".badge_dynamic.settings.patterns[$i].color // \"orange\"" "$config_file")

        echo "🟢 Value $label"
        echo "🟢 Label $override_label"
        echo "🟢 Default label $default_label"
        if [[ "$pull_request_body" == *"$pattern"* ]];then
            echo "🟢 Pattern $pattern found in the pull request body for badge $label at index $i"
            dynamic_badge="![Static Badge](https://img.shields.io/badge/$default_label-$value-grey?label=$override_label&labelColor=grey&color=${color})"
            #dynamic_badge="![Static Badge](https://img.shields.io/badge/${label}-${value}-${color})"
            all_badges=$(echo $all_badges $dynamic_badge)
        fi
    done
fi

# Add delimiter for next replacement
all_badges=$(printf "<!--begin:badgetizr--> \n%s\n<!--end:badgetizr-->" "$all_badges")

# Build new body
new_pull_request_body=$(printf "%s\n%s" "$all_badges" "$pull_request_body")
# Send the new body
gh pr edit $BITRISE_PULL_REQUEST -b "$new_pull_request_body"
