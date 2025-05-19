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

# Check if the backup.sh file exists
if [ ! -f "${SCRIPTS_DIR}/backup.sh" ]; then
    echo "backup.sh file not found"
    exit 2
fi

#cf_auth # Authenticate to cloud.gov # TODO: Uncomment when done testing locally
validate_s3_service_binding "$CF_S3_BACKUP_SERVICE_NAME" # Ensure the backup bucket is bound

IFS=',' read -ra TARGET_SERVICES <<< "$CF_S3_TARGET_SERVICE_NAMES" # Comma-separated list of target services
for target_service in "${TARGET_SERVICES[@]}"; do
    #cf run-task "$CF_APP_NAME" --name "backup-$target_service" --command "${SCRIPTS_DIR}/backup.sh $target_service $BACKUP_SERVICE" # TODO: Uncomment when done testing locally

    "${SCRIPTS_DIR}/backup.sh" "$target_service"
done
