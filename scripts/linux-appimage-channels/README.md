# Linux AppImage Channels

This directory manages a local two-channel Linux AppImage setup:

- `Open Design Stable` handles `od://`
- `Open Design Dev` handles `od-dev://`
- channel symlinks and versioned AppImages live under `$HOME/Applications/OpenDesign/appimages`
- both channels share `$HOME/Applications/OpenDesign/runtime/linux/namespaces/default/data`

From the repo root:

```bash
pnpm linux:appimage:channels status
pnpm linux:appimage:channels setup
pnpm linux:appimage:channels build-dev --pull
pnpm linux:appimage:channels promote-dev
pnpm linux:appimage:channels clean
pnpm linux:appimage:channels backup-data
```

Direct script use also works:

```bash
scripts/linux-appimage-channels/linux-appimage-channels.sh status
```

Typical flow:

1. Update Dev from the current checkout:

   ```bash
   pnpm linux:appimage:channels build-dev
   ```

2. Pull first, then update Dev:

   ```bash
   pnpm linux:appimage:channels build-dev --pull
   ```

3. Promote the current Dev AppImage to Stable:

   ```bash
   pnpm linux:appimage:channels promote-dev
   ```

Stable stays pinned to its versioned AppImage until promoted again. Dev moves whenever
`build-dev` installs a new AppImage.

Environment overrides:

```bash
OPEN_DESIGN_INSTALL_ROOT=$HOME/Applications/OpenDesign
OPEN_DESIGN_CHANNEL_APPIMAGE_DIR=$HOME/Applications/OpenDesign/appimages
OPEN_DESIGN_NAMESPACE=default
OPEN_DESIGN_BACKUP_ROOT=$PWD/.tmp/open-design-data-backups
```
