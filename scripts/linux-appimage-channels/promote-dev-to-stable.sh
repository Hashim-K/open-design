#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

usage() {
  cat <<'EOF'
Usage: promote-dev-to-stable.sh

Pins Stable to the currently installed Dev AppImage. Future Dev builds will move
only the Dev symlink until this script is run again.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
[[ $# -eq 0 ]] || od_die "unknown option: $1"

dev_target="$(od_realpath "$(od_channel_appimage dev)")"
[[ -n "$dev_target" && -f "$dev_target" ]] || od_die "Dev AppImage is missing or broken"

ln -sfn "$dev_target" "$(od_channel_appimage stable)"
ln -sfn "$(od_channel_appimage stable)" "$(od_channel_bin_link stable)"
"$SCRIPT_DIR/setup-launchers.sh" --archive-old-appimages

od_log "Stable promoted to: $dev_target"
