#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

TARGET_SERVICE_NAME="$1"
BACKUP_SERVICE_NAME="$2"

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

validate_target_s3_service_binding "$TARGET_SERVICE_NAME" "$BACKUP_SERVICE_NAME"
set_aws_s3_credentials "$BACKUP_SERVICE_NAME"

BACKUP_BUCKET_ID=$(get_bucket_id "$BACKUP_SERVICE_NAME")
TARGET_BUCKET_ID=$(get_bucket_id "$TARGET_SERVICE_NAME")

aws s3 sync --exact-timestamps "s3://${TARGET_BUCKET_ID}" "s3://${BACKUP_BUCKET_ID}/${TARGET_SERVICE_NAME}/$(date '+%Y-%m-%d')"

