#!/usr/bin/env bash
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${ROOT}/site/"
DRY=""

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY="--dry-run"
elif [[ $# -gt 0 ]]; then
    echo "Использование: scripts/deploy.sh [--dry-run]" >&2
    exit 1
fi

[[ -f "${LOCAL_DIR}index.html" ]] || {
    echo "Ошибка: site/index.html отсутствует" >&2
    exit 1
}

git -C "$ROOT" diff --quiet &&
git -C "$ROOT" diff --cached --quiet || {
    echo "Ошибка: есть незафиксированные изменения" >&2
    exit 1
}

rsync -avz --delete $DRY \
    "$LOCAL_DIR" "${REMOTE}:${REMOTE_DIR}/"

[[ -n "$DRY" ]] && exit 0

ssh "$REMOTE" \
    "find /var/www/devops-site -type d -exec chmod 755 {} \; &&
     find /var/www/devops-site -type f -exec chmod 644 {} \; &&
     curl -fsS --cacert /etc/ssl/certs/devops.crt \
     --resolve devops.local:443:127.0.0.1 \
     https://devops.local >/dev/null"

echo "Развёрнут коммит: $(git -C "$ROOT" rev-parse --short HEAD)"
