# macOS Ventura on Proxmox 9 (Intel) - Fallback Path

Use this path if latest/Tahoe behavior is unstable on your host.

## Requirements

- Intel CPU with VT-x enabled
- Proxmox 9
- `local-lvm` storage
- 8 GB+ RAM (16 GB recommended)

------------------------------------------------------------------------

## 1) Build VM 900 baseline

```bash
qm stop 900 || true
qm destroy 900 --purge 1 --destroy-unreferenced-disks 1 || true

qm create 900 \
  --name macos-hulki \
  --machine pc-q35-8.1 \
  --bios ovmf \
  --cores 4 \
  --sockets 1 \
  --memory 16384 \
  --balloon 0 \
  --ostype other \
  --scsihw virtio-scsi-pci \
  --net0 vmxnet3,bridge=vmbr0 \
  --vga vmware \
  --agent 1 \
  --tablet 1 \
  --onboot 0

qm set 900 --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0
qm set 900 --sata0 local-lvm:100,cache=none,discard=on,ssd=1
```

------------------------------------------------------------------------

## 2) OpenCore as RAW on `ide0`

```bash
/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"

cd /var/lib/vz/template/iso
qemu-img convert -f raw -O raw opencore-osx-proxmox-vm.iso opencore.raw
qm importdisk 900 opencore.raw local-lvm

qm config 900 | grep '^unused'
# Example: unused0: local-lvm:vm-900-disk-2
qm set 900 --ide0 local-lvm:vm-900-disk-2
```

------------------------------------------------------------------------

## 3) Ventura recovery on `ide2`

Ventura board-id:

`Mac-B4831CEBD52A0C4C`

Use the helper script:

```bash
scripts/make_ventura_recovery_fat.sh \
  /root/com.apple.recovery.ventura \
  /var/lib/vz/template/iso/recovery-ventura-fat.img
```

Import and attach:

```bash
qm importdisk 900 /var/lib/vz/template/iso/recovery-ventura-fat.img local-lvm
qm config 900 | grep '^unused'
# Example: unused2: local-lvm:vm-900-disk-6
qm set 900 --ide2 local-lvm:vm-900-disk-6
```

------------------------------------------------------------------------

## 4) Apply stability args + boot order

```bash
qm set 900 --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -device usb-mouse,bus=ehci.0,port=3 -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu Cascadelake-Server,vendor=GenuineIntel,+invtsc,-pcid,-hle,-rtm,-avx512f,-avx512dq,-avx512cd,-avx512bw,-avx512vl,-avx512vnni,kvm=on,vmware-cpuid-freq=on'
qm set 900 --boot "order=ide0;ide2;sata0"
qm start 900
```

------------------------------------------------------------------------

## 5) Installer steps

In OpenCore:
1. `Reset NVRAM` once
2. `Install macOS Ventura`

If no target volume is large enough:
1. Back
2. Disk Utility
3. View -> Show All Devices
4. Select `QEMU HARDDISK Media` (~107 GB)
5. Erase as:
   - Name: `Macintosh HD`
   - Format: `APFS`
   - Scheme: `GUID Partition Map`
6. Retry install

------------------------------------------------------------------------

## 6) Post-install cleanup

```bash
qm set 900 --boot "order=ide0;sata0"
# optional
qm set 900 --delete ide2
qm snapshot 900 clean-install
```
