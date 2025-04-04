#!/bin/bash
set -e

# ========================
# ⚙️ Partitioning disk for EFI + LUKS
# ========================

# Make sure SETUP_DISK is set
if [[ -z "$SETUP_DISK" || ! -b "$SETUP_DISK" ]]; then
  echo "❌ SETUP_DISK is not set or is not a valid block device"
  exit 1
fi

echo "🔧 Partitioning $SETUP_DISK for EFI + encrypted root..."

# Destroy existing partition table
parted --script "$SETUP_DISK" mklabel gpt

# Create EFI partition
parted --script "$SETUP_DISK" mkpart ESP fat32 1MiB 513MiB set 1 esp on

# Create root partition (to be encrypted)
parted --script "$SETUP_DISK" mkpart primary ext4 513MiB 100%

# Optional: show result
echo
lsblk "$SETUP_DISK"

# Save partitions to variables
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
echo "✅ Partitioning complete."
echo "📦 EFI:  $SETUP_PART_EFI"
echo "🔐 ROOT: $SETUP_PART_ROOT (to be encrypted)"

