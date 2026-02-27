# macOS Tahoe on Proxmox 9 (Intel) - Recommended Path

## What this path does

- Uses OpenCore + Apple Recovery with `-os latest`.
- On this host, latest mapped to Tahoe-track recovery.
- If Apple changes the latest channel, you may get a different latest release.

## Requirements

- Intel CPU with VT-x enabled
- Proxmox 9
- `local-lvm` storage
- 6 GB+ free RAM for test boot (16 GB preferred for installer/runtime)

------------------------------------------------------------------------

## 1) Create/prepare VM 901

```bash
qm stop 901 || true
qm destroy 901 --purge 1 --destroy-unreferenced-disks 1 || true

qm create 901 \
  --name macos-tahoe-test \
  --machine pc-q35-8.1 \
  --bios ovmf \
  --cores 4 \
  --sockets 1 \
  --memory 6144 \
  --balloon 0 \
  --ostype other \
  --scsihw virtio-scsi-pci \
  --net0 vmxnet3,bridge=vmbr0 \
  --vga vmware \
  --agent 1 \
  --tablet 1 \
  --onboot 0

qm set 901 --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0
qm set 901 --sata0 local-lvm:100,cache=none,discard=on,ssd=1
```

------------------------------------------------------------------------

## 2) OpenCore as RAW on `ide0`

```bash
/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"

cd /var/lib/vz/template/iso
qemu-img convert -f raw -O raw opencore-osx-proxmox-vm.iso opencore.raw
qm importdisk 901 opencore.raw local-lvm

qm config 901 | grep '^unused'
# Example: unused0: local-lvm:vm-901-disk-2
qm set 901 --ide0 local-lvm:vm-901-disk-2
```

------------------------------------------------------------------------

## 3) Build latest (Tahoe-track) recovery image on `ide2`

Board-id used for latest track:

`Mac-7BA5B2D9E42DDD94`

Use the helper script:

```bash
scripts/make_latest_recovery_fat.sh \
  /root/com.apple.recovery.tahoe \
  /var/lib/vz/template/iso/recovery-tahoe-fat.img
```

Or equivalent manual command:

```bash
python3 /root/OSX-PROXMOX/tools/macrecovery/macrecovery.py \
  -b Mac-7BA5B2D9E42DDD94 \
  -m 00000000000000000 \
  -os latest \
  -o /root/com.apple.recovery.tahoe \
  download
```

Import and attach:

```bash
qm importdisk 901 /var/lib/vz/template/iso/recovery-tahoe-fat.img local-lvm
qm config 901 | grep '^unused'
# Example: unused0: local-lvm:vm-901-disk-3
qm set 901 --ide2 local-lvm:vm-901-disk-3
```

------------------------------------------------------------------------

## 4) Apply stability args + boot order

```bash
qm set 901 --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -device usb-mouse,bus=ehci.0,port=3 -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu Cascadelake-Server,vendor=GenuineIntel,+invtsc,-pcid,-hle,-rtm,-avx512f,-avx512dq,-avx512cd,-avx512bw,-avx512vl,-avx512vnni,kvm=on,vmware-cpuid-freq=on'
qm set 901 --boot "order=ide0;ide2;sata0"
qm start 901
```

Important:
- Do not set `-v` in QEMU args.
- If keyboard layout is wrong in noVNC, set layout inside macOS UI first.

------------------------------------------------------------------------

## 5) Install flow

In OpenCore:
1. Run `Reset NVRAM` once.
2. Select installer entry for the latest macOS recovery.

If installer says no target volume is large enough:
1. Back
2. Disk Utility
3. View -> Show All Devices
4. Select `QEMU HARDDISK Media` (~107 GB)
5. Erase:
   - Name: `Macintosh HD`
   - Format: `APFS`
   - Scheme: `GUID Partition Map`
6. Retry install

------------------------------------------------------------------------

## 6) Verify it is Tahoe track

Check the installer title/version text inside recovery UI.

- If it is Tahoe/latest: continue.
- If it resolves to another latest release: either continue with that latest build or switch to Ventura fallback docs.
