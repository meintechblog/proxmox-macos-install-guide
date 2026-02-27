# Troubleshooting

## Tahoe/latest vs Ventura fallback

- Start with Tahoe/latest path first.
- If latest repeatedly stalls on your hardware, switch to Ventura fallback path.
- Keep both path docs handy:
  - `docs/INSTALL_TAHOE.md`
  - `docs/INSTALL_VENTURA.md`

## Apple logo freeze

Symptoms:
- Apple logo appears
- No progress, installer stalls

Fixes:
1. Use machine type `pc-q35-8.1`.
2. Use OpenCore on `ide0` and recovery on `ide2`.
3. Use tested CPU args:
   - `Cascadelake-Server`
   - `+invtsc`
   - `vmware-cpuid-freq=on`
4. Ensure recovery board-id matches your path:
   - Tahoe/latest path: `Mac-7BA5B2D9E42DDD94` with `-os latest`
   - Ventura fallback path: `Mac-B4831CEBD52A0C4C`

## No volume large enough in installer

Cause:
- Target 100 GB disk is present but not initialized.

Fix:
1. Back
2. Disk Utility
3. View -> Show All Devices
4. Select `QEMU HARDDISK Media` (~107 GB)
5. Erase with:
   - Name: `Macintosh HD`
   - Format: `APFS`
   - Scheme: `GUID Partition Map`

## QEMU error: `kvm: -v: invalid option`

Cause:
- `-v` was put in QEMU args.

Fix:
- Remove `-v` from `qm set --args`.
- Verbose belongs to OpenCore boot args, not QEMU args.

## Keyboard mismatch (US vs DE)

- Usually set keyboard in macOS UI (top-right) first.
- Optional Proxmox setting:
  - `qm set 900 --keyboard de`
- Reconnect noVNC after changing keyboard settings.
