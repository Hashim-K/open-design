#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
. "$SCRIPT_DIR/env.sh"

pull=false
containerized=false
archive_old=true
app_version=""

usage() {
  cat <<'EOF'
Usage: build-dev-appimage.sh [--pull] [--containerized] [--app-version VERSION] [--keep-old-appimages]

Builds Open Design from the dev repo, installs the result as the Dev channel,
refreshes launchers, and keeps Stable pinned until promote-dev-to-stable.sh is run.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull) pull=true; shift ;;
    --containerized) containerized=true; shift ;;
    --app-version)
      [[ $# -ge 2 ]] || od_die "--app-version requires a value"
      app_version="$2"
      shift 2
      ;;
    --keep-old-appimages) archive_old=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) od_die "unknown option: $1" ;;
  esac
done

od_require_repo
mkdir -p "$OPEN_DESIGN_APP_DIR" "$OPEN_DESIGN_INSTALL_ROOT"

cd "$OPEN_DESIGN_REPO"

if [[ "$pull" == true ]]; then
  od_log "pulling latest changes in $OPEN_DESIGN_REPO"
  git pull --ff-only
fi

commit="$(git rev-parse --short=9 HEAD)"
version="$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync('package.json','utf8')).version)")"
timestamp="$(date +%Y%m%d-%H%M%S)"
json_file="$(mktemp)"
trap 'rm -f "$json_file"' EXIT

cmd=(pnpm tools-pack linux build --to appimage --namespace "$OPEN_DESIGN_NAMESPACE" --dir "$OPEN_DESIGN_INSTALL_ROOT" --json)
if [[ "$containerized" == true ]]; then
  cmd+=(--containerized)
fi
if [[ -n "$app_version" ]]; then
  cmd+=(--app-version "$app_version")
  version="$app_version"
fi

od_log "building Dev AppImage from $OPEN_DESIGN_REPO@$commit"
"${cmd[@]}" | tee "$json_file"

appimage_path="$(
  node -e '
    const fs = require("fs");
    const payload = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (!payload.appImagePath) process.exit(2);
    console.log(payload.appImagePath);
  ' "$json_file"
)"

[[ -f "$appimage_path" ]] || od_die "build did not produce an AppImage at: $appimage_path"

target="$OPEN_DESIGN_APP_DIR/Open-Design.dev-$version-$commit-$timestamp.AppImage"
install -m 0755 "$appimage_path" "$target"
ln -sfn "$target" "$(od_channel_appimage dev)"
ln -sfn "$(od_channel_appimage dev)" "$(od_channel_bin_link dev)"

if [[ ! -e "$(od_channel_appimage stable)" ]]; then
  ln -sfn "$target" "$(od_channel_appimage stable)"
fi

setup_args=()
if [[ "$archive_old" == true ]]; then
  setup_args+=(--archive-old-appimages)
fi
"$SCRIPT_DIR/setup-launchers.sh" "${setup_args[@]}"

od_log "Dev now points to: $target"
od_log "Stable still points to: $(od_realpath "$(od_channel_appimage stable)")"
