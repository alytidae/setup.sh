#!/bin/bash
set -e

DISK="${SETUP_DISK:?SETUP_DISK not set}"

echo "💥 Wiping $DISK and creating new GPT layout..."

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
echo "⏳ Waiting for kernel to detect new partitions..."

# ⌛ Ждём появления разделов
for dev in 1 2; do
  part="${DISK}${dev}"
  [[ "$DISK" == *"nvme"* ]] && part="${DISK}p${dev}"

  for i in {1..20}; do
    if [[ -b "$part" ]]; then
      echo "📦 Found $part"
      break
    fi
    sleep 0.2
  done

  # Если не появилось — ошибка
  if [[ ! -b "$part" ]]; then
    echo "❌ Partition $part did not appear. Aborting."
    exit 1
  fi
done

# 📤 Экспорт переменных
if [[ "$DISK" == *"nvme"* ]]; then
  export SETUP_PART_EFI="${DISK}p1"
  export SETUP_PART_ROOT="${DISK}p2"
else
  export SETUP_PART_EFI="${DISK}1"
  export SETUP_PART_ROOT="${DISK}2"
fi

echo "✅ EFI:  $SETUP_PART_EFI"
echo "✅ ROOT: $SETUP_PART_ROOT (to be encrypted)"
