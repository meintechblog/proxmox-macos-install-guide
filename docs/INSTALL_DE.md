# macOS Ventura auf Proxmox 9 (Intel) - Praxiserprobte Installationsroutine

## Basis-Anleitung (als Referenz)
https://www.xda-developers.com/i-installed-macos-on-proxmox-and-it-works-well/

## Voraussetzungen

- Intel CPU mit VT-x aktiviert
- Proxmox 9
- Storage `local-lvm` vorhanden
- Mindestens 8 GB RAM (empfohlen 16 GB)
- Vorhandene Bridge (hier: `vmbr0`)

------------------------------------------------------------------------

## 0) Host-Sicherheit (wichtig)

Diese Routine aendert nur VM `900`.

- Kein Edit von `/etc/default/grub`
- Keine Kernel-/Modul-Aenderungen
- Keine BIOS-Aenderungen

------------------------------------------------------------------------

## 1) TSC pruefen (wichtig ab Monterey)

```bash
dmesg | grep -i -e tsc -e clocksource
cat /sys/devices/system/clocksource/clocksource0/current_clocksource
```

Erwartet:

    clocksource: Switched to clocksource tsc
    tsc

------------------------------------------------------------------------

## 2) VM 900 neu erstellen (Baseline)

Falls `900` schon existiert:

```bash
qm stop 900 || true
qm destroy 900 --purge 1 --destroy-unreferenced-disks 1
```

Neu erstellen:

```bash
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

## 3) OpenCore erzeugen

```bash
/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"
```

Abfragen:
- Generate serial -> `y`
- SystemProductName -> `iMacPro1,1`
- Apply changes -> `y`
- Reboot -> Enter

------------------------------------------------------------------------

## 4) OpenCore ISO -> RAW importieren

```bash
cd /var/lib/vz/template/iso
qemu-img convert -f raw -O raw opencore-osx-proxmox-vm.iso opencore.raw
qm importdisk 900 opencore.raw local-lvm
```

Dann OpenCore als `ide0` einhaengen (nicht als CD-ROM):

```bash
qm config 900 | grep '^unused'
# Beispiel: unused0: local-lvm:vm-900-disk-2
qm set 900 --ide0 local-lvm:vm-900-disk-2
```

------------------------------------------------------------------------

## 5) Ventura-Recovery korrekt laden (entscheidend)

Wichtig: Fuer Ventura die passende Board-ID verwenden:

`Mac-B4831CEBD52A0C4C`

```bash
python3 /root/OSX-PROXMOX/tools/macrecovery/macrecovery.py \
  -b Mac-B4831CEBD52A0C4C \
  -m 00000000000000000 \
  -o /root/com.apple.recovery.ventura \
  download
```

Dann FAT-Recovery-Image mit `com.apple.recovery.boot` bauen:

```bash
fallocate -x -l 1024M /var/lib/vz/template/iso/recovery-ventura-fat.img
mkfs.msdos -F 32 /var/lib/vz/template/iso/recovery-ventura-fat.img
mkdir -p /mnt/recovery-ventura
LOOPDEV=$(losetup -f --show /var/lib/vz/template/iso/recovery-ventura-fat.img)
mount "$LOOPDEV" /mnt/recovery-ventura
mkdir -p /mnt/recovery-ventura/com.apple.recovery.boot
cp /root/com.apple.recovery.ventura/BaseSystem.dmg /mnt/recovery-ventura/com.apple.recovery.boot/
cp /root/com.apple.recovery.ventura/BaseSystem.chunklist /mnt/recovery-ventura/com.apple.recovery.boot/
sync
umount /mnt/recovery-ventura
losetup -d "$LOOPDEV"
rmdir /mnt/recovery-ventura
```

Import und als `ide2` einhaengen:

```bash
qm importdisk 900 /var/lib/vz/template/iso/recovery-ventura-fat.img local-lvm
qm config 900 | grep '^unused'
# Beispiel: unused2: local-lvm:vm-900-disk-6
qm set 900 --ide2 local-lvm:vm-900-disk-6
```

------------------------------------------------------------------------

## 6) Stabilitaets-Args setzen (Apple-Logo-Freeze-Fix)

```bash
qm set 900 --args '-device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -device usb-mouse,bus=ehci.0,port=3 -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu Cascadelake-Server,vendor=GenuineIntel,+invtsc,-pcid,-hle,-rtm,-avx512f,-avx512dq,-avx512cd,-avx512bw,-avx512vl,-avx512vnni,kvm=on,vmware-cpuid-freq=on'
qm set 900 --boot "order=ide0;ide2;sata0"
```

Wichtig:
- Kein `-v` in `qm set --args`
- Verbose gehoert in OpenCore-Bootargs, nicht in QEMU-Args

Optional (nur falls noVNC/OpenCore immer US-Layout liefert):

```bash
qm set 900 --keyboard de
```

Hinweis: Nicht immer noetig. Oft reicht in der macOS-UI oben rechts die Tastatur auf Deutsch zu stellen.

------------------------------------------------------------------------

## 7) Start + Installation

```bash
qm start 900
```

In OpenCore:
- einmal `Reset NVRAM`
- dann `Install macOS Ventura`

Wenn im Installer "kein Volume gross genug" erscheint:
1. `Back`
2. `Disk Utility`
3. `View` -> `Show All Devices`
4. `QEMU HARDDISK Media` (ca. 107 GB) auswaehlen
5. `Erase`:
   - Name: `Macintosh HD`
   - Format: `APFS`
   - Scheme: `GUID Partition Map`
6. Disk Utility schliessen und Ventura-Installation erneut starten

------------------------------------------------------------------------

## Nach erfolgreichem Erststart

Recovery aus Boot-Reihenfolge nehmen:

```bash
qm set 900 --boot "order=ide0;sata0"
```

Optional Recovery entfernen:

```bash
qm set 900 --delete ide2
```

Optional Snapshot:

```bash
qm snapshot 900 clean-install
```

------------------------------------------------------------------------

## Typische Probleme & Ursachen

| Problem | Ursache | Fix |
| --- | --- | --- |
| UEFI Shell | OpenCore falsch eingebunden | OpenCore als RAW importieren und als `ide0` mounten |
| Apple-Logo ohne Fortschritt | CPU/Machine-Kombi unguenstig | `pc-q35-8.1` + Cascadelake-Args wie oben |
| Recovery bootet, aber spaeter Stall | Falsche Board-ID beim Recovery-Download | Ventura mit `Mac-B4831CEBD52A0C4C` neu laden |
| `kvm: -v: invalid option` | `-v` in QEMU-Args gesetzt | `qm set 900 --args ...` ohne `-v` |
| Kein Installationsvolume gross genug | 100GB-Disk nicht initialisiert | Disk Utility -> Show All Devices -> 107GB Disk als APFS/GUID erase |
| Tastatur wirkt wie US | noVNC/OpenCore/macOS-Layout nicht synchron | In macOS oben rechts Deutsch waehlen; optional `qm set 900 --keyboard de` |

------------------------------------------------------------------------

## Kurz-Empfehlung

- Ventura statt Sonoma/Sequoia fuer mehr Stabilitaet
- Vor macOS-Updates immer Snapshot
- Keine Host-Tweaks, solange VM mit obiger Konfig stabil bootet
