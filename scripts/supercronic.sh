#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/bin:${PATH}"

# Latest releases available at https://github.com/aptible/supercronic/releases
SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-arm64
SUPERCRONIC_SHA1SUM=e0f0c06ebc5627e43b25475711e694450489ab00
SUPERCRONIC=supercronic-linux-arm64

if ! command -v supercronic &> /dev/null
then
    curl -fsSLO "$SUPERCRONIC_URL" \
        && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
        && chmod +x "$SUPERCRONIC" \
        && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
        && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Absolute path to this script's directory
# Check if the backup-all.sh file exists
if [ ! -f "${SCRIPTS_DIR}/backup-all.sh" ]; then
    echo "backup-all.sh file not found"
    exit 2
fi

echo "${S3_BACKUP_TASK_CRON_EXPRESSION:-'0 0 * * *'} ${SCRIPTS_DIR}/backup-all.sh" > "${SCRIPTS_DIR}/../crontab"

supercronic "${SCRIPTS_DIR}/../crontab"
