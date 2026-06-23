#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: linux-appimage-channels.sh <command> [args]

Commands:
  status       Show channel links, desktop entries, protocols, icons, and data health
  setup        Refresh Stable/Dev launchers and protocol handlers
  build-dev    Build the current dev repo into the Dev AppImage channel
  promote-dev  Pin Stable to the current Dev AppImage
  clean        Remove stale Open Design launchers/icons and archive unreferenced AppImages
  backup-data  Back up the shared Open Design data/config directory

Examples:
  scripts/linux-appimage-channels/linux-appimage-channels.sh status
  scripts/linux-appimage-channels/linux-appimage-channels.sh build-dev --pull
  scripts/linux-appimage-channels/linux-appimage-channels.sh promote-dev
  pnpm linux:appimage:channels status

Environment overrides:
  OPEN_DESIGN_INSTALL_ROOT=$HOME/Applications/OpenDesign
  OPEN_DESIGN_NAMESPACE=default
EOF
}

command="${1:-}"
if [[ -z "$command" || "$command" == "-h" || "$command" == "--help" ]]; then
  usage
  exit 0
fi
shift

case "$command" in
  status) exec "$SCRIPT_DIR/status.sh" "$@" ;;
  setup) exec "$SCRIPT_DIR/setup-launchers.sh" "$@" ;;
  build-dev) exec "$SCRIPT_DIR/build-dev-appimage.sh" "$@" ;;
  promote-dev) exec "$SCRIPT_DIR/promote-dev-to-stable.sh" "$@" ;;
  clean) exec "$SCRIPT_DIR/clean-stale.sh" "$@" ;;
  backup-data) exec "$SCRIPT_DIR/backup-data.sh" "$@" ;;
  *) usage >&2; exit 2 ;;
esac
