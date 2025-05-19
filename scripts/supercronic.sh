#!/usr/bin/env bash
set -euo pipefail

DEBUG="${DEBUG:-false}" # Set to true or 1 to enable debug logging
BIN_DIR="${BIN_DIR:-/usr/local/bin}"

export PATH="${BIN_DIR}:${PATH}"

# Latest releases available at https://github.com/aptible/supercronic/releases
SUPERCRONIC=supercronic-linux-amd64
SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/v0.2.33/${SUPERCRONIC}"
SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8

if ! command -v supercronic &> /dev/null
then
    curl -fsSLO "$SUPERCRONIC_URL" \
        && echo "${SUPERCRONIC_SHA1SUM} ${SUPERCRONIC}" | sha1sum -c - \
        && chmod +x "$SUPERCRONIC" \
        && mv "$SUPERCRONIC" "${BIN_DIR}/${SUPERCRONIC}" \
        && ln -s "${BIN_DIR}/${SUPERCRONIC}" "${BIN_DIR}/supercronic"
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Absolute path to this script's directory

# Check if the required files exist
REQUIRED_FILES=(
    "${SCRIPTS_DIR}/backup-buckets.sh"
    "${SCRIPTS_DIR}/prune-buckets.sh"
)
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Required file $file not found"
        exit 2
    fi
done

# Generate the crontab file
echo "${S3_BACKUP_TASK_CRON_EXPRESSION:-0 0 * * *} ${SCRIPTS_DIR}/backup-buckets.sh" > "${SCRIPTS_DIR}/../crontab"
echo "${S3_PRUNE_TASK_CRON_EXPRESSION:-0 0 * * *} ${SCRIPTS_DIR}/prune-buckets.sh" >> "${SCRIPTS_DIR}/../crontab"

SUPERCRONIC_FLAGS=()
if [[ "$DEBUG" == "true" || "$DEBUG" == 1 ]]; then
    SUPERCRONIC_FLAGS+=('-debug')
fi

supercronic "${SUPERCRONIC_FLAGS[@]}" "${SCRIPTS_DIR}/../crontab"
