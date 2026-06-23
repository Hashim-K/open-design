#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

archive_old=true

usage() {
  cat <<'EOF'
Usage: clean-stale.sh [--menu-only]

Removes stale AppImageLauncher Open Design menu entries and stale Open Design
icons. By default it also archives versioned AppImages that are not pointed to
by Stable or Dev.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --menu-only) archive_old=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) od_die "unknown option: $1" ;;
  esac
done

od_remove_stale_desktop_entries
od_remove_top_level_channel_appimages
od_remove_stale_icons

if [[ "$archive_old" == true ]]; then
  od_archive_unreferenced_appimages
fi

od_refresh_desktop_caches

od_log "stale launchers/icons cleaned"
if [[ "$archive_old" == true ]]; then
  od_log "unreferenced AppImages archived under: $OPEN_DESIGN_ARCHIVE_DIR"
fi
