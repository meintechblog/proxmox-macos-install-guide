# proxmox-macos-ventura-guide

Practical, tested guide to run macOS Ventura on Proxmox 9 (Intel) with OpenCore.

## Scope

- Host: Proxmox VE 9
- CPU: Intel (VT-x)
- Guest: macOS Ventura installer + install flow
- Focus: stable boot, Apple-logo freeze mitigation, safe host handling

## Important Safety Notes

- This project changes VM config only.
- It does not require host GRUB/kernel/module changes.
- Keep backups/snapshots before major VM changes.

## Quick Start

1. Read [docs/INSTALL_DE.md](docs/INSTALL_DE.md) (full step-by-step).
2. Use `scripts/make_ventura_recovery_fat.sh` to build the Ventura recovery FAT image.
3. Use `scripts/vm900_rebuild.sh` to rebuild VM 900 with stable defaults.
4. In macOS installer, erase the 100+ GB target disk as `APFS + GUID`.

## Repo Layout

- `docs/INSTALL_DE.md` - full German install routine (current working baseline)
- `docs/TROUBLESHOOTING.md` - common issues and exact fixes
- `scripts/make_ventura_recovery_fat.sh` - create FAT recovery image with `com.apple.recovery.boot`
- `scripts/vm900_rebuild.sh` - rebuild VM 900 with tested settings
- `scripts/post_install_cleanup.sh` - cleanup after successful install

## Disclaimer

Use at your own risk. Ensure legal and licensing compliance for your environment.
