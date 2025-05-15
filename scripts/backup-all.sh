#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

function cf_auth {
    echo "Initiating cloud.gov login... "
    cf api "$CF_API_URL"

    echo ""
    cf auth # Reads CF_USERNAME & CF_PASSWORD from the environment

    echo ""
    echo "Setting cloud.gov target organization and space... "
    cf target -o "$CF_ORG_NAME" -s "$CF_ORG_SPACE"
}

# Check if the functions.sh file exists
if [ ! -f "${SCRIPTS_DIR}/functions.sh" ]; then
    echo "functions.sh file not found"
    exit 2
fi
source "${SCRIPTS_DIR}/functions.sh"

cf_auth # Authenticate to cloud.gov
validate_backup_s3_service_binding # Ensure the backup bucket is bound
BACKUP_SERVICE=$(echo "$CF_S3_CONFIG" | jq -r '.backup')

mapfile -t TARGET_SERVICES < <(echo "$CF_S3_CONFIG" | jq -r '.targets[]')

for target_service in "${TARGET_SERVICES[@]}"; do
    cf run-task "$CF_APP_NAME" --name "backup-$target_service" --command "${SCRIPTS_DIR}/backup.sh $target_service $BACKUP_SERVICE"
done
