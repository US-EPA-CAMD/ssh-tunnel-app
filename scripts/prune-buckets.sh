#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

# Check if the prune-bucket.sh file exists
if [ ! -f "${SCRIPTS_DIR}/prune-bucket.sh" ]; then
    echo "prune-bucket.sh file not found"
    exit 2
fi

#cf_auth # Authenticate to cloud.gov # TODO: Uncomment when done testing locally
validate_s3_service_binding "$CF_S3_BACKUPS_SERVICE_NAME" # Ensure the backup bucket is bound

IFS=',' read -ra TARGET_SERVICES <<< "$CF_S3_BACKUP_TARGET_SERVICE_NAMES" # Comma-separated list of target services
for target_service in "${TARGET_SERVICES[@]}"; do
    #cf run-task "$CF_APP_NAME" --name "prune-$target_service" --command "${SCRIPTS_DIR}/prune-bucket.sh $target_service" # TODO: Uncomment when done testing locally

    "${SCRIPTS_DIR}/prune-bucket.sh" "$target_service"
done
