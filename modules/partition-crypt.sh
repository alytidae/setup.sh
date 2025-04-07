#!/bin/bash
set -e

# ========== Settings ==========
DISK="${SETUP_DISK:?SETUP_DISK not set}"

echo "💥 Wiping $DISK and creating new GPT layout..."

# ========== Create partitions via fdisk ==========
fdisk "$DISK" <<EOF
g
n
1

+512M
t
1
n
2


w
EOF

echo "✅ Partitioning complete (fdisk)"

# ========== Reload partition table ==========
echo "🔁 Running partprobe..."
partprobe "$DISK"
udevadm settle

# ========== Wait for partitions to appear ==========
for dev in 1 2; do
  part="${DISK}${dev}"
  # for nvme devices add 'p' between disk and number
  [[ "$DISK" == *"nvme"* ]] && part="${DISK}p${dev}"

  until [ -b "$part" ]; do
    echo "⏳ Waiting for $part..."
    sleep 0.2
  done
done

# ========== Export partition paths ==========
if [[ "$DISK" == *"nvme"* ]]; then
  export SETUP_EFI="${DISK}p1"
  export SETUP_ROOT="${DISK}p2"
else
  export SETUP_EFI="${DISK}1"
  export SETUP_ROOT="${DISK}2"
fi

echo "📦 EFI: $SETUP_EFI"
echo "📦 ROOT: $SETUP_ROOT (to be encrypted)"
