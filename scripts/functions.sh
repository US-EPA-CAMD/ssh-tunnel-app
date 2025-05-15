#!/usr/bin/env bash
set -euo pipefail

function get_bucket_id {
    echo "$VCAP_SERVICES" | jq -r --arg name "$1" '.s3[] | select(.name == $name) | .credentials.bucket'
}

# Function to get AWS S3 credentials from VCAP_SERVICES
function _set_aws_s3_credentials {
    s3_service_name=$1
    service_type=$2

    echo "Checking for $service_type $s3_service_name"

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

function validate_backup_s3_service_binding {
    # CF_S3_CONFIG should look like:
    # {
    #   "backup": "my-backup-bucket",
    #   "targets": ["logs-bucket", "archive-bucket"]
    # }

    # Parse expected value
    expected_backup_name=$(echo "$CF_S3_CONFIG" | jq -r '.backup')

    # Locate the correct backup service by name
    backup_index=$(echo "$VCAP_SERVICES" | jq --arg name "$expected_backup_name" '.s3 | map(.name == $name) | index(true)')

    if [ "$backup_index" == "null" ]; then
        echo "Could not find expected backup S3 service: $expected_backup_name"
        exit 1
    fi
}

function validate_target_s3_service_binding {
    validate_backup_s3_service_binding

    target_service_name="$1"
    backup_service_name="$2"

    target_index=$(echo "$VCAP_SERVICES" | jq --arg name "$target_service_name" '.s3 | map(.name == $name) | index(true)')

    if [ "$target_index" == "null" ]; then
        echo "Could not find expected target S3 service: $target_service_name"
        exit 1
    fi

    bucket_id=$(get_bucket_id "$target_service_name")
    echo "$bucket_id"
    additional_buckets_index=$(echo "$VCAP_SERVICES" | jq --arg id "$bucket_id" --arg backup "$backup_service_name" '.s3[] | select(.name == $backup) | .credentials.additional_buckets | index($id)')

    if [ "$additional_buckets_index" == "null" ]; then
        echo "Target S3 service $target_service_name is not listed as an additional bucket in the backup S3 service $backup_service_name"
        exit 1
    fi
}
