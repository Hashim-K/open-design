#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

printf 'Open Design maintenance status\n'
printf '\n'
printf 'Repo:        %s\n' "$OPEN_DESIGN_REPO"
printf 'Namespace:   %s\n' "$OPEN_DESIGN_NAMESPACE"
printf 'Install:     %s\n' "$OPEN_DESIGN_INSTALL_ROOT"
printf 'Data:        %s\n' "$OPEN_DESIGN_DATA_ROOT"
printf '\n'

for channel in stable dev; do
  link="$(od_channel_appimage "$channel")"
  printf '%-7s link: %s\n' "$channel" "$link"
  printf '%-7s real: %s\n' "$channel" "$(od_realpath "$link")"
done

printf '\nDesktop entries:\n'
find "$OPEN_DESIGN_DESKTOP_DIR" -maxdepth 1 \( -name '*open-design*.desktop' -o -name 'appimagekit_*Open_Design.desktop' \) -printf '  %f\n' 2>/dev/null | sort || true

printf '\nProtocol handlers:\n'
if od_have xdg-mime; then
  printf '  od:     %s\n' "$(xdg-mime query default x-scheme-handler/od 2>/dev/null || true)"
  printf '  od-dev: %s\n' "$(xdg-mime query default x-scheme-handler/od-dev 2>/dev/null || true)"
else
  printf '  xdg-mime not installed\n'
fi

printf '\nIcons:\n'
find "$OPEN_DESIGN_ICON_BASE" -maxdepth 1 -name 'open-design-*.png' -printf '  %f\n' 2>/dev/null | sort || true

printf '\nData check:\n'
if [[ -f "$OPEN_DESIGN_DATA_ROOT/app.sqlite" ]] && od_have sqlite3; then
  sqlite3 "$OPEN_DESIGN_DATA_ROOT/app.sqlite" "pragma integrity_check; select id || ' | ' || name from projects order by name;"
elif [[ -f "$OPEN_DESIGN_DATA_ROOT/app.sqlite" ]]; then
  printf '  app.sqlite exists, sqlite3 not installed\n'
else
  printf '  app.sqlite not found\n'
fi

printf '\nRunning processes:\n'
pgrep -af 'Open-Design|\.mount_Open|tools-pack' | grep -v 'pgrep -af' || printf '  none\n'

printf '\nArchive:\n'
if [[ -d "$OPEN_DESIGN_ARCHIVE_DIR" ]]; then
  find "$OPEN_DESIGN_ARCHIVE_DIR" -maxdepth 1 -name '*.AppImage' -printf '  %f\n' 2>/dev/null | sort || true
else
  printf '  not created\n'
fi
