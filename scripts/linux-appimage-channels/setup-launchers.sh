#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

archive_old=false

usage() {
  cat <<'EOF'
Usage: setup-launchers.sh [--archive-old-appimages]

Creates/refreshes the Open Design Stable and Open Design Dev launchers.
Both channels use the shared namespace/data root. Stable owns od:// and Dev owns od-dev://.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive-old-appimages) archive_old=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) od_die "unknown option: $1" ;;
  esac
done

mkdir -p "$OPEN_DESIGN_APP_DIR" "$OPEN_DESIGN_BIN_DIR" "$OPEN_DESIGN_DESKTOP_DIR" "$OPEN_DESIGN_ICON_BASE"

stable_appimage="$(od_channel_appimage stable)"
dev_appimage="$(od_channel_appimage dev)"

if [[ ! -e "$stable_appimage" || ! -e "$dev_appimage" ]]; then
  latest="$(od_latest_versioned_appimage)"
  if [[ -n "$latest" ]]; then
    [[ -e "$stable_appimage" ]] || ln -sfn "$latest" "$stable_appimage"
    [[ -e "$dev_appimage" ]] || ln -sfn "$latest" "$dev_appimage"
  fi
fi

[[ -e "$stable_appimage" ]] || od_die "stable AppImage link is missing: $stable_appimage"
[[ -e "$dev_appimage" ]] || od_die "dev AppImage link is missing: $dev_appimage"

ln -sfn "$stable_appimage" "$(od_channel_bin_link stable)"
ln -sfn "$dev_appimage" "$(od_channel_bin_link dev)"

od_remove_stale_desktop_entries
od_remove_stale_icons

if [[ -f "$OPEN_DESIGN_ICON_SRC" ]]; then
  install -Dm644 "$OPEN_DESIGN_ICON_SRC" "$(od_icon_path stable)"
  install -Dm644 "$OPEN_DESIGN_ICON_SRC" "$(od_icon_path dev)"
else
  od_log "icon source not found, leaving existing icons in place: $OPEN_DESIGN_ICON_SRC"
fi

cat >"$(od_desktop_file stable)" <<EOF
[Desktop Entry]
Type=Application
Name=Open Design Stable
GenericName=Open Design
Comment=Open Design stable build
Exec=env -u APPIMAGE -u APPDIR -u ELECTRON_RUN_AS_NODE -u XDG_CONFIG_HOME APPIMAGELAUNCHER_DISABLE=1 OD_PACKAGED_NAMESPACE=$OPEN_DESIGN_NAMESPACE $stable_appimage --appimage-extract-and-run %U
Icon=open-design-stable
Categories=Development;
StartupWMClass=Open Design
StartupNotify=true
Terminal=false
MimeType=x-scheme-handler/od;
EOF

cat >"$(od_desktop_file dev)" <<EOF
[Desktop Entry]
Type=Application
Name=Open Design Dev
GenericName=Open Design
Comment=Open Design development build
Exec=env -u APPIMAGE -u APPDIR -u ELECTRON_RUN_AS_NODE -u XDG_CONFIG_HOME APPIMAGELAUNCHER_DISABLE=1 OD_PACKAGED_NAMESPACE=$OPEN_DESIGN_NAMESPACE $dev_appimage --appimage-extract-and-run %U
Icon=open-design-dev
Categories=Development;
StartupWMClass=Open Design
StartupNotify=true
Terminal=false
MimeType=x-scheme-handler/od-dev;
EOF

chmod 0644 "$(od_desktop_file stable)" "$(od_desktop_file dev)"

if od_have desktop-file-validate; then
  desktop-file-validate "$(od_desktop_file stable)" "$(od_desktop_file dev)"
fi

if od_have xdg-mime; then
  xdg-mime default open-design-stable.desktop x-scheme-handler/od
  xdg-mime default open-design-dev.desktop x-scheme-handler/od-dev
fi

if [[ "$archive_old" == true ]]; then
  od_archive_unreferenced_appimages
fi

od_refresh_desktop_caches

od_log "Stable: $stable_appimage -> $(od_realpath "$stable_appimage")"
od_log "Dev:    $dev_appimage -> $(od_realpath "$dev_appimage")"
od_log "Data:   $OPEN_DESIGN_DATA_ROOT"
