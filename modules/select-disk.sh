#!/bin/bash
set -e

# ========================
# 📋 Show available disks
# ========================
echo "📋 Available disks:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT | grep -v loop
echo

# ========================
# 🧾 Prompt for disk input
# ========================
while true; do
  read -e -p "Enter the disk device (e.g. /dev/sda, /dev/nvme0n1): " DISK

  # Check if the disk exists and is a block device
  if [[ ! -b "$DISK" ]]; then
    echo "❌ $DISK does not exist or is not a block device. Try again."
    continue
  fi

  # Check for mounted partitions
  MOUNTED_PARTS=$(lsblk -n -o MOUNTPOINT "$DISK" | grep -v '^$' || true)
  if [[ -n "$MOUNTED_PARTS" ]]; then
    echo "⚠️ Some partitions on $DISK are currently mounted:"
    echo "$MOUNTED_PARTS"
    echo "Please unmount them manually before proceeding."
    exit 1
  fi

  # ========================
  # 🔍 Check for existing filesystems
  # ========================
  echo
  echo "🔍 Scanning partitions on $DISK for existing filesystems..."

  PARTS=$(lsblk -ln -o NAME "$DISK" | tail -n +2)  # skip main disk

  for PART in $PARTS; do
    DEV="/dev/$PART"
    FSTYPE=$(lsblk -ln -o FSTYPE "$DEV" | head -n 1)

    if [[ -n "$FSTYPE" ]]; then
      echo "⚠️  Found filesystem '$FSTYPE' on $DEV"
    fi
  done

  echo
  echo "⚠️ WARNING: The disk may contain existing filesystems."
  echo "ALL DATA on $DISK and its partitions will be permanently destroyed!"

  # First confirmation
  read -p "Are you sure you want to continue? Type 'yes' to confirm: " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "❌ Operation canceled."
    exit 1
  fi

  # Second, stronger confirmation
  read -p "This is your LAST chance. Type 'YES' (in capital letters) to continue: " FINAL_CONFIRM
  if [[ "$FINAL_CONFIRM" != "YES" ]]; then
    echo "❌ Operation canceled."
    exit 1
  fi

  break
done

# ========================
# ✅ Disk confirmed
# ========================
echo "✅ Disk $DISK selected for installation."

# Make disk path available to other modules
export SETUP_DISK="$DISK"
