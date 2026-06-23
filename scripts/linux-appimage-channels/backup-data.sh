#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

usage() {
  cat <<'EOF'
Usage: backup-data.sh

Creates a tar.gz backup of the shared Open Design data/config directory.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
[[ $# -eq 0 ]] || od_die "unknown option: $1"

[[ -d "$OPEN_DESIGN_DATA_ROOT" ]] || od_die "data root not found: $OPEN_DESIGN_DATA_ROOT"
mkdir -p "$OPEN_DESIGN_BACKUP_ROOT"

stamp="$(date +%Y%m%d-%H%M%S)"
backup="$OPEN_DESIGN_BACKUP_ROOT/open-design-shared-data-$stamp.tar.gz"
tmp_backup="$backup.tmp"
staging="$(mktemp -d)"
cleanup() {
  rm -rf "$staging"
  rm -f "$tmp_backup"
}
trap cleanup EXIT

mkdir -p "$staging/data"

if od_have rsync; then
  rsync -a \
    --exclude app.sqlite \
    --exclude app.sqlite-shm \
    --exclude app.sqlite-wal \
    "$OPEN_DESIGN_DATA_ROOT/" "$staging/data/"
else
  tar -C "$OPEN_DESIGN_DATA_ROOT" \
    --exclude ./app.sqlite \
    --exclude ./app.sqlite-shm \
    --exclude ./app.sqlite-wal \
    --warning=no-file-changed \
    --ignore-failed-read \
    -cf - . | tar -C "$staging/data" -xf -
fi

if [[ -f "$OPEN_DESIGN_DATA_ROOT/app.sqlite" ]]; then
  if od_have sqlite3; then
    sqlite3 "$OPEN_DESIGN_DATA_ROOT/app.sqlite" ".backup '$staging/data/app.sqlite'"
  else
    cp -p "$OPEN_DESIGN_DATA_ROOT"/app.sqlite* "$staging/data/" 2>/dev/null || true
  fi
fi

tar -C "$staging" -czf "$tmp_backup" data
mv "$tmp_backup" "$backup"

od_log "backup written: $backup"
