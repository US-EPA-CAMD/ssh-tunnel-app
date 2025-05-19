#!/usr/bin/env bash
set -euo pipefail

resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local directory
        directory="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$directory/$source"
    done
    cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd
}

# Help section
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") <TARGET_SERVICE_NAME> <BACKUP_DATE>"
    echo
    echo "Restore a backup from the backup S3 bucket to a target S3 bucket."
    echo
    echo "Arguments:"
    echo "  TARGET_SERVICE_NAME   Name of the bound target S3 service to restore into."
    echo "  BACKUP_DATE           Date of the backup to restore, in YYYY-MM-DD format."
    echo
    echo "Environment Variables:"
    echo "  CF_S3_BACKUPS_SERVICE_NAME   Name of the bound S3 backup service."
    echo
    echo "Example:"
    echo "  $(basename "$0") example-bucket 2025-05-13"
    exit 0
fi

TARGET_SERVICE_NAME="$1"
BACKUP_DATE="$2" # YYYY-MM-DD

BACKUP_SERVICE_NAME="$CF_S3_BACKUPS_SERVICE_NAME"
SCRIPTS_DIR="$(resolve_script_path)"

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

validate_s3_service_binding "$TARGET_SERVICE_NAME" "$BACKUP_SERVICE_NAME"
set_aws_s3_credentials "$BACKUP_SERVICE_NAME"

BACKUP_BUCKET_ID=$(get_bucket_id "$BACKUP_SERVICE_NAME")
TARGET_BUCKET_ID=$(get_bucket_id "$TARGET_SERVICE_NAME")

echo "Restoring backup from bucket \"${BACKUP_SERVICE_NAME}\" to bucket \"${TARGET_SERVICE_NAME}\" for date $BACKUP_DATE"

aws_s3_sync "s3://${BACKUP_BUCKET_ID}/${TARGET_SERVICE_NAME}/${BACKUP_DATE}"  "s3://${TARGET_BUCKET_ID}"

echo "Backup restore for ${TARGET_SERVICE_NAME} completed successfully."
