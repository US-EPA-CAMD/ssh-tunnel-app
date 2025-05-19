#!/usr/bin/env bash
set -euo pipefail

DEBUG="${DEBUG:-false}" # Set to true or 1 to enable debug logging

function aws_s3_generate_metadata {
    uri="$1"

    metadata_file="/tmp/metadata.json"

    # Generate metadata file and stage it in /tmp
    aws_global_flags=('--output' 'text' '--color' 'off' '--no-cli-pager' '--no-cli-auto-prompt')
    # If DEBUG is set to true or 1, enable debug logging
    if [[ "$DEBUG" == "true" || "$DEBUG" == 1 ]]; then
        aws_global_flags+=('--debug')
    fi

    aws "${aws_global_flags[@]}" \
        s3 ls \
        "$uri" \
        --recursive \
        | awk '{$1=$1; print}' \
        | while read -r date time size key; do echo "{\"timestamp\": \"${date} ${time}\", \"size\": ${size}, \"key\": \"${key}\"}"; done \
        | jq -s '.' > "$metadata_file"

    if [[ "$DEBUG" != "true" && "$DEBUG" != 1 ]]; then
        # If DEBUG is not set to true or 1, use --quiet to suppress output
        aws_global_flags+=('--quiet')
    fi

    # Upload the metadata file to S3
    aws "${aws_global_flags[@]}" \
        s3 cp \
        "$metadata_file" \
        "${uri}/metadata.json"
}

function aws_s3_prune {
    uri="$1"
    cutoff_date="$2"

    service_name="$(basename "$uri")"

    aws_global_flags=('--output' 'text' '--color' 'off' '--no-cli-pager' '--no-cli-auto-prompt')
    # If DEBUG is set to true or 1, enable debug logging
    if [[ "$DEBUG" == "true" || "$DEBUG" == 1 ]]; then
        aws_global_flags+=('--debug')
    fi

    # Get a sorted list of backup directories (dates), oldest to newest
    backup_dirs=()
    while read -r dir; do
        backup_dirs+=("${dir%/}")  # Remove trailing slash
        done < <( \
            aws "${aws_global_flags[@]}" \
            s3 ls \
            "${uri}/" \
            | awk '/PRE/ {print $2}' \
            | sort \
        )

    if [[ "$DEBUG" != "true" && "$DEBUG" != 1 ]]; then
        # If DEBUG is not set to true or 1, use --quiet to suppress output
        aws_global_flags+=('--quiet')
    fi

    s3_flags=('--recursive' '--dryrun') # TODO: Remove --dryrun to actually delete
    total_backups="${#backup_dirs[@]}"
    for ((i = 0; i < total_backups; i++)); do
        backup_date="${backup_dirs[$i]}"
        if [[ "$backup_date" < "$cutoff_date" ]]; then
            # Only delete if there's at least one newer backup
            if (( i < total_backups - 1 )); then
                echo "Deleting old backup: ${service_name}/${backup_date}"
                aws "${aws_global_flags[@]}" \
                    s3 rm \
                    "${uri}/${backup_date}" \
                    "${s3_flags[@]}"
            else
                echo "Skipping deletion of last remaining backup: ${service_name}/${backup_date}"
            fi
        fi
    done
}

function aws_s3_sync {
    source_uri="$1"
    destination_uri="$2"

    aws_global_flags=('--output' 'json' '--color' 'off' '--no-cli-pager' '--no-cli-auto-prompt')
    s3_flags=('--exact-timestamps' '--delete')
    # If DEBUG is set to true or 1, enable debug logging
    if [[ "$DEBUG" == "true" || "$DEBUG" == 1 ]]; then
        aws_global_flags+=('--debug')
    else
        # Otherwise, use --quiet to suppress output
        aws_global_flags+=('--quiet')
    fi

    aws "${aws_global_flags[@]}" \
        s3 sync \
        "$source_uri" \
        "$destination_uri" \
        "${s3_flags[@]}"
}

function cf_auth {
    echo "Initiating cloud.gov login... "
    cf api "$CF_API_URL"

    echo ""
    cf auth # Reads CF_USERNAME & CF_PASSWORD from the environment

    echo ""
    echo "Setting cloud.gov target organization and space... "
    cf target -o "$CF_ORG_NAME" -s "$CF_ORG_SPACE"
}

function get_bucket_id {
    echo "$VCAP_SERVICES" | jq -r --arg name "$1" '.s3[] | select(.name == $name) | .credentials.bucket'
}

# Function to get AWS S3 credentials from VCAP_SERVICES
function _set_aws_s3_credentials {
    s3_service_name=$1
    service_type=$2

    echo "Setting credentials for $service_type service \"${s3_service_name}\""

    _get_credential() {
        credential_key="$1"
        jq -r --arg service_type "$service_type" \
            --arg credential_key "$credential_key" \
            --arg s3_service_name "$s3_service_name" \
            '.[$service_type]?[] | select(.name == $s3_service_name) | .credentials[$credential_key]' \
            <<< "${VCAP_SERVICES}"
    }

    AWS_ACCESS_KEY_ID=$(_get_credential 'access_key_id'); export AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY=$(_get_credential 'secret_access_key'); export AWS_SECRET_ACCESS_KEY
    AWS_DEFAULT_REGION=$(_get_credential 'region'); export AWS_DEFAULT_REGION
}

# Function to get AWS credentials from VCAP_SERVICES
function set_aws_s3_credentials {
    s3_service_name=$1

    _set_aws_s3_credentials "$s3_service_name" "s3"

    if [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
        _set_aws_s3_credentials "s3_service_name" "user-provided"
    fi

    # Check if credentials were properly set
    : "${AWS_ACCESS_KEY_ID:?AWS S3 not configured}"
    : "${AWS_SECRET_ACCESS_KEY:?AWS S3 not configured}"
    : "${AWS_DEFAULT_REGION:?AWS S3 not configured}"

    echo "Set credentials for S3"
}

function validate_s3_service_binding {
    target_service_name="$1"
    primary_service_name="${2:-}"

    # Locate the correct service by name
    service_index=$(echo "$VCAP_SERVICES" | jq --arg name "$target_service_name" '.s3 | map(.name == $name) | index(true)')

    if [ "$service_index" == "null" ]; then
        echo "Could not find expected S3 service: $target_service_name"
        exit 1
    fi

    # If a primary service name is provided, check if the target service is listed as an additional bucket
    if [ -n "$primary_service_name" ]; then
        validate_s3_service_binding "$primary_service_name"

        bucket_id=$(get_bucket_id "$target_service_name")
        additional_buckets_index=$(echo "$VCAP_SERVICES" | jq --arg id "$bucket_id" --arg primary "$primary_service_name" '.s3[] | select(.name == $primary) | .credentials.additional_buckets | index($id)')

        if [ "$additional_buckets_index" == "null" ]; then
            echo "Target S3 service $target_service_name is not listed as an additional bucket in the primary S3 service $primary_service_name"
            exit 1
        fi
    fi
}
