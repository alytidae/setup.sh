#!/bin/bash
set -e

# ========================
# ⚙️ Partitioning disk for EFI + LUKS using fdisk
# ========================

# Make sure SETUP_DISK is set
if [[ -z "$SETUP_DISK" || ! -b "$SETUP_DISK" ]]; then
  echo "❌ SETUP_DISK is not set or is not a valid block device"
  exit 1
fi

echo "🔧 Partitioning $SETUP_DISK with fdisk..."

# Destroy existing partition table and create new GPT layout
sgdisk --zap-all "$SETUP_DISK"

fdisk "$SETUP_DISK" <<EOF
g             # Create new GPT partition table
n             # New partition (EFI)
1             # Partition number
              # Default first sector
+512M         # Last sector
t             # Change partition type
1             # Select partition 1
1             # EFI System

n             # New partition (root)
2             # Partition number
              # Default first sector
              # Use rest of the disk
t             # Change type
2             # Select partition 2
20            # Linux filesystem (ext4/btrfs)

w             # Write changes
EOF

# Optional: show result
echo
lsblk "$SETUP_DISK"

# Set environment variables
if [[ "$SETUP_DISK" == *"nvme"* ]]; then
  SETUP_PART_EFI="${SETUP_DISK}p1"
  SETUP_PART_ROOT="${SETUP_DISK}p2"
else
  SETUP_PART_EFI="${SETUP_DISK}1"
  SETUP_PART_ROOT="${SETUP_DISK}2"
fi

export SETUP_PART_EFI
export SETUP_PART_ROOT

echo
echo "✅ Partitioning complete (fdisk)."
echo "📦 EFI:  $SETUP_PART_EFI"
echo "🔐 ROOT: $SETUP_PART_ROOT (to be encrypted)"
