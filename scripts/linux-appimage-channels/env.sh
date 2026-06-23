#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'env.sh is meant to be sourced by the Open Design maintenance scripts.\n' >&2
  exit 2
fi

set -euo pipefail

OPEN_DESIGN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OPEN_DESIGN_REPO_ROOT="$(cd -- "$OPEN_DESIGN_SCRIPT_DIR/../.." && pwd)"

OPEN_DESIGN_REPO="${OPEN_DESIGN_REPO:-$OPEN_DESIGN_REPO_ROOT}"
OPEN_DESIGN_NAMESPACE="${OPEN_DESIGN_NAMESPACE:-default}"
OPEN_DESIGN_APP_DIR="${OPEN_DESIGN_APP_DIR:-$HOME/Applications}"
OPEN_DESIGN_INSTALL_ROOT="${OPEN_DESIGN_INSTALL_ROOT:-$OPEN_DESIGN_APP_DIR/OpenDesign}"
OPEN_DESIGN_DATA_ROOT="${OPEN_DESIGN_DATA_ROOT:-$OPEN_DESIGN_INSTALL_ROOT/runtime/linux/namespaces/$OPEN_DESIGN_NAMESPACE/data}"
OPEN_DESIGN_ARCHIVE_DIR="${OPEN_DESIGN_ARCHIVE_DIR:-$OPEN_DESIGN_INSTALL_ROOT/archive/appimages}"
OPEN_DESIGN_BACKUP_ROOT="${OPEN_DESIGN_BACKUP_ROOT:-$OPEN_DESIGN_REPO/.tmp/open-design-data-backups}"
OPEN_DESIGN_DESKTOP_DIR="${OPEN_DESIGN_DESKTOP_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/applications}"
OPEN_DESIGN_ICON_BASE="${OPEN_DESIGN_ICON_BASE:-${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps}"
OPEN_DESIGN_BIN_DIR="${OPEN_DESIGN_BIN_DIR:-$HOME/.local/bin}"
OPEN_DESIGN_ICON_SRC="${OPEN_DESIGN_ICON_SRC:-$OPEN_DESIGN_REPO/tools/pack/resources/linux/icon.png}"

od_log() {
  printf '[open-design] %s\n' "$*" >&2
}

od_die() {
  printf '[open-design] error: %s\n' "$*" >&2
  exit 1
}

od_have() {
  command -v "$1" >/dev/null 2>&1
}

od_require_repo() {
  [[ -d "$OPEN_DESIGN_REPO" ]] || od_die "Open Design repo not found: $OPEN_DESIGN_REPO"
  [[ -f "$OPEN_DESIGN_REPO/package.json" ]] || od_die "not an Open Design repo: $OPEN_DESIGN_REPO"
}

od_channel_appimage() {
  case "${1:-}" in
    stable|dev) printf '%s/Open-Design.%s.AppImage\n' "$OPEN_DESIGN_APP_DIR" "$1" ;;
    *) od_die "unknown channel: ${1:-}" ;;
  esac
}

od_channel_bin_link() {
  case "${1:-}" in
    stable|dev) printf '%s/Open-Design.%s.AppImage\n' "$OPEN_DESIGN_BIN_DIR" "$1" ;;
    *) od_die "unknown channel: ${1:-}" ;;
  esac
}

od_desktop_file() {
  case "${1:-}" in
    stable|dev) printf '%s/open-design-%s.desktop\n' "$OPEN_DESIGN_DESKTOP_DIR" "$1" ;;
    *) od_die "unknown channel: ${1:-}" ;;
  esac
}

od_icon_path() {
  case "${1:-}" in
    stable|dev) printf '%s/open-design-%s.png\n' "$OPEN_DESIGN_ICON_BASE" "$1" ;;
    *) od_die "unknown channel: ${1:-}" ;;
  esac
}

od_realpath() {
  readlink -f "$1" 2>/dev/null || true
}

od_latest_versioned_appimage() {
  find "$OPEN_DESIGN_APP_DIR" -maxdepth 1 -type f -name 'Open-Design*.AppImage' \
    ! -name 'Open-Design.stable.AppImage' \
    ! -name 'Open-Design.dev.AppImage' \
    ! -name 'Open-Design.default.AppImage' \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | sed -n '1s/^[^ ]* //p'
}

od_refresh_desktop_caches() {
  if od_have update-desktop-database; then
    update-desktop-database "$OPEN_DESIGN_DESKTOP_DIR" >/dev/null 2>&1 || true
  fi
  if od_have gtk-update-icon-cache; then
    gtk-update-icon-cache -q "${OPEN_DESIGN_ICON_BASE%/512x512/apps}" >/dev/null 2>&1 || true
  fi
}

od_archive_unreferenced_appimages() {
  local stable_target dev_target file resolved
  stable_target="$(od_realpath "$(od_channel_appimage stable)")"
  dev_target="$(od_realpath "$(od_channel_appimage dev)")"
  mkdir -p "$OPEN_DESIGN_ARCHIVE_DIR"

  while IFS= read -r -d '' file; do
    resolved="$(od_realpath "$file")"
    [[ -n "$resolved" ]] || continue
    [[ "$resolved" == "$stable_target" || "$resolved" == "$dev_target" ]] && continue
    mv -n "$file" "$OPEN_DESIGN_ARCHIVE_DIR/"
  done < <(find "$OPEN_DESIGN_APP_DIR" -maxdepth 1 -type f -name 'Open-Design*.AppImage' -print0 2>/dev/null)
}

od_remove_stale_desktop_entries() {
  local file
  shopt -s nullglob
  for file in \
    "$OPEN_DESIGN_DESKTOP_DIR"/appimagekit_*Open_Design.desktop \
    "$OPEN_DESIGN_DESKTOP_DIR"/open-design-default.desktop \
    "$OPEN_DESIGN_DESKTOP_DIR"/open-design-pr4494.desktop
  do
    rm -f "$file"
  done
  shopt -u nullglob
}

od_remove_stale_icons() {
  rm -f \
    "$OPEN_DESIGN_ICON_BASE/open-design-default.png" \
    "$OPEN_DESIGN_ICON_BASE/open-design-pr4494.png"
}
