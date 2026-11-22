#!/bin/bash
#
# Deploy the Selfprint marketing site (selfprint.org). Static files only - no
# build step. Atomically swaps the files into the droplet's web root and pings
# IndexNow. The app lives separately at try.selfprint.org.
#
#   ./deploy.sh        (or: npm run deploy)
#
set -euo pipefail

RESET="\033[0m"; GREEN="\033[32m"; BLUE="\033[34m"; BOLD="\033[1m"; RED="\033[31m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SERVER="root@167.99.114.235"            # same droplet (also hosts try.selfprint.org)
SERVER_PATH="/var/www/selfprint"        # nginx: root /var/www/selfprint/dist
REMOTE_DIR="dist"
INDEXNOW_HOST="selfprint.org"
INDEXNOW_KEY="8801e36d85ea742c9d5498b1b76c01ed"

# The files that make up the public site (everything else - deploy.sh, README,
# indexnow.mjs, .sent.json, .git - stays out of the deploy).
FILES=(
  index.html privacy.html terms.html site.css
  robots.txt sitemap.xml llms.txt
  favicon.svg favicon.ico apple-touch-icon.png og.png
  fonts "${INDEXNOW_KEY}.txt"
)

echo -e "${BLUE}${BOLD}Deploying selfprint.org to ${SERVER}:${SERVER_PATH}${RESET}\n"

TEMP_DIR="$(mktemp -d)"
tar -czf "${TEMP_DIR}/site.tar.gz" "${FILES[@]}"

echo "Preparing server (atomic swap with rollback backup)..."
ssh "${SERVER}" bash -s <<EOF
set -e
mkdir -p ${SERVER_PATH}
cd ${SERVER_PATH}
rm -rf ${REMOTE_DIR}.bak 2>/dev/null || true
[ -d "${REMOTE_DIR}" ] && mv ${REMOTE_DIR} ${REMOTE_DIR}.bak
mkdir -p ${REMOTE_DIR}
EOF

echo "Uploading..."
scp "${TEMP_DIR}/site.tar.gz" "${SERVER}:${SERVER_PATH}/site.tar.gz"

ssh "${SERVER}" bash -s <<EOF
set -e
cd ${SERVER_PATH}
tar -xzf site.tar.gz -C ${REMOTE_DIR}
rm site.tar.gz
date > ${REMOTE_DIR}/version.txt
EOF

rm -rf "${TEMP_DIR}"

echo "Notifying IndexNow..."
node "${SCRIPT_DIR}/indexnow.mjs" \
  --host "${INDEXNOW_HOST}" \
  --key "${INDEXNOW_KEY}" \
  --sitemap "https://${INDEXNOW_HOST}/sitemap.xml" \
  --state "${SCRIPT_DIR}/.sent.json" \
  || echo -e "${RED}IndexNow ping failed (deploy itself succeeded)${RESET}"

echo -e "\n${GREEN}${BOLD}selfprint.org deployed.${RESET}"
echo -e "Rollback (on the server): cd ${SERVER_PATH} && rm -rf ${REMOTE_DIR} && mv ${REMOTE_DIR}.bak ${REMOTE_DIR}"
