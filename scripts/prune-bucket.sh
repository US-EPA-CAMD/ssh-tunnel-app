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
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <TARGET_SERVICE_NAME>"
    echo
    echo "Prune the backups for the specified S3 service."
    echo
    echo "Arguments:"
    echo "  TARGET_SERVICE_NAME   Name of the bound S3 service to prune."
    echo
    echo "Environment Variables:"
    echo "  CF_S3_BACKUPS_SERVICE_NAME   Name of the bound S3 backup service."
    echo
    echo "Example:"
    echo "  $(basename "$0") example-bucket"
    exit 0
fi

TARGET_SERVICE_NAME="$1"

BACKUP_SERVICE_NAME="$CF_S3_BACKUPS_SERVICE_NAME"
RETENTION_DAYS="${CF_S3_BACKUP_RETENTION_DAYS:-30}"  # Default to 30 days if unset
SCRIPTS_DIR="$(resolve_script_path)"

CUTOFF_DATE="$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%d)"

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

validate_s3_service_binding "$BACKUP_SERVICE_NAME"
set_aws_s3_credentials "$BACKUP_SERVICE_NAME"

echo "Pruning backups for ${TARGET_SERVICE_NAME} older than ${CUTOFF_DATE}..."

BACKUP_BUCKET_ID=$(get_bucket_id "$BACKUP_SERVICE_NAME")

aws_s3_prune "s3://${BACKUP_BUCKET_ID}/${TARGET_SERVICE_NAME}" "$CUTOFF_DATE"

echo "Pruning for ${TARGET_SERVICE_NAME} completed successfully."
