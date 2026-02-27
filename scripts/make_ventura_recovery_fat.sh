#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${1:-/root/com.apple.recovery.ventura}"
IMG="${2:-/var/lib/vz/template/iso/recovery-ventura-fat.img}"
MNT="/mnt/recovery-ventura"
BOARD_ID="Mac-B4831CEBD52A0C4C"
MLB="00000000000000000"

if [[ ! -x /root/OSX-PROXMOX/tools/macrecovery/macrecovery.py ]]; then
  echo "ERROR: /root/OSX-PROXMOX/tools/macrecovery/macrecovery.py not found" >&2
  exit 1
fi

python3 /root/OSX-PROXMOX/tools/macrecovery/macrecovery.py \
  -b "$BOARD_ID" -m "$MLB" -o "$OUTDIR" download

rm -f "$IMG"
fallocate -x -l 1024M "$IMG"
mkfs.msdos -F 32 "$IMG" >/dev/null

mkdir -p "$MNT"
LOOPDEV=$(losetup -f --show "$IMG")
cleanup() {
  set +e
  mountpoint -q "$MNT" && umount "$MNT"
  [[ -n "${LOOPDEV:-}" ]] && losetup -d "$LOOPDEV" 2>/dev/null
  rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

mount "$LOOPDEV" "$MNT"
mkdir -p "$MNT/com.apple.recovery.boot"
cp "$OUTDIR/BaseSystem.dmg" "$MNT/com.apple.recovery.boot/"
cp "$OUTDIR/BaseSystem.chunklist" "$MNT/com.apple.recovery.boot/"
sync
umount "$MNT"
losetup -d "$LOOPDEV"
LOOPDEV=""
rmdir "$MNT" || true
trap - EXIT

echo "OK: created $IMG"
