#!/usr/bin/env bash
set -euo pipefail

VMID="${1:-900}"

qm set "$VMID" --boot "order=ide0;sata0"

echo "Optional next step: qm set $VMID --delete ide2"
echo "Optional snapshot: qm snapshot $VMID clean-install"
