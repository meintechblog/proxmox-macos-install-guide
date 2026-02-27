# proxmox-macos-ventura-guide

Practical, tested guide to run macOS on Proxmox 9 (Intel) with OpenCore.

## Scope

- Host: Proxmox VE 9
- CPU: Intel (VT-x)
- Guest: macOS Tahoe (recommended) and macOS Ventura (fallback)
- Focus: stable boot, Apple-logo freeze mitigation, safe host handling

## Important Safety Notes

- This project changes VM config only.
- It does not require host GRUB/kernel/module changes.
- Keep backups/snapshots before major VM changes.

## Quick Start

1. Read [docs/INSTALL.md](docs/INSTALL.md) to choose your install path.
2. Recommended path: [docs/INSTALL_TAHOE.md](docs/INSTALL_TAHOE.md).
3. Fallback path: [docs/INSTALL_VENTURA.md](docs/INSTALL_VENTURA.md).
4. Build recovery images with:
   - Tahoe/latest: `scripts/make_latest_recovery_fat.sh`
   - Ventura: `scripts/make_ventura_recovery_fat.sh`
5. Rebuild a VM with tested defaults: `scripts/vm900_rebuild.sh`.

## Repo Layout

- `docs/INSTALL.md` - install path chooser (Tahoe vs Ventura)
- `docs/INSTALL_TAHOE.md` - recommended latest/Tahoe path
- `docs/INSTALL_VENTURA.md` - Ventura fallback path
- `docs/TROUBLESHOOTING.md` - common issues and exact fixes
- `scripts/make_latest_recovery_fat.sh` - create latest/Tahoe-style FAT recovery image
- `scripts/make_ventura_recovery_fat.sh` - create FAT recovery image with `com.apple.recovery.boot`
- `scripts/vm900_rebuild.sh` - rebuild VM 900 with tested settings
- `scripts/post_install_cleanup.sh` - cleanup after successful install

## Upstream Resources (as referenced in XDA article)

- OpenCore ISO project:
  - https://github.com/LongQT-sea/OpenCore-ISO
  - https://github.com/LongQT-sea/OpenCore-ISO/releases
- macOS installer/recovery image builder:
  - https://github.com/LongQT-sea/macos-iso-builder
  - https://github.com/LongQT-sea/macos-iso-builder/releases

## Disclaimer

Use at your own risk. Ensure legal and licensing compliance for your environment.
