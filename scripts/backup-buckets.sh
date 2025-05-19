#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Absolute path to this script's directory

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

# Check if the backup-bucket.sh file exists
if [ ! -f "${SCRIPTS_DIR}/backup-bucket.sh" ]; then
    echo "backup-bucket.sh file not found"
    exit 2
fi

cf_auth # Authenticate to cloud.gov
validate_s3_service_binding "$CF_S3_BACKUPS_SERVICE_NAME" # Ensure the backup bucket is bound

IFS=',' read -ra TARGET_SERVICES <<< "$CF_S3_BACKUP_TARGET_SERVICE_NAMES" # Comma-separated list of target services
for target_service in "${TARGET_SERVICES[@]}"; do
    cf run-task \
        "$(get_app_name)" \
        --name "backup-$target_service" \
        --command "${SCRIPTS_DIR}/backup-bucket.sh $target_service"
done
