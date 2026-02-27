#!/usr/bin/env bash
set -euo pipefail

VMID="${1:-900}"
BRIDGE="${2:-vmbr0}"
STORAGE="${3:-local-lvm}"
OPENCORE_VOLID="${4:-local-lvm:vm-${VMID}-disk-2}"
RECOVERY_VOLID="${5:-local-lvm:vm-${VMID}-disk-6}"

# DANGER: destroys VM if it exists
if qm config "$VMID" >/dev/null 2>&1; then
  qm stop "$VMID" || true
  qm destroy "$VMID" --purge 1 --destroy-unreferenced-disks 1
fi

qm create "$VMID" \
  --name macos-hulki \
  --machine pc-q35-8.1 \
  --bios ovmf \
  --cores 4 \
  --sockets 1 \
  --memory 16384 \
  --balloon 0 \
  --ostype other \
  --scsihw virtio-scsi-pci \
  --net0 vmxnet3,bridge="$BRIDGE" \
  --vga vmware \
  --agent 1 \
  --tablet 1 \
  --onboot 0

qm set "$VMID" --efidisk0 "$STORAGE":1,efitype=4m,pre-enrolled-keys=0
qm set "$VMID" --sata0 "$STORAGE":100,cache=none,discard=on,ssd=1

qm set "$VMID" --ide0 "$OPENCORE_VOLID"
qm set "$VMID" --ide2 "$RECOVERY_VOLID"

qm set "$VMID" --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -device usb-mouse,bus=ehci.0,port=3 -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu Cascadelake-Server,vendor=GenuineIntel,+invtsc,-pcid,-hle,-rtm,-avx512f,-avx512dq,-avx512cd,-avx512bw,-avx512vl,-avx512vnni,kvm=on,vmware-cpuid-freq=on'
qm set "$VMID" --boot "order=ide0;ide2;sata0"

echo "OK: VM $VMID rebuilt"
qm config "$VMID"
