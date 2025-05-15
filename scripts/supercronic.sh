#!/usr/bin/env bash
set -euo pipefail

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

/usr/local/bin/supercronic "$(dirname "${BASH_SOURCE[0]}")/../crontab"
