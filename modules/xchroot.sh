#!/bin/bash
set -e

echo "chroot and reconfigure"

cp /etc/resolv.conf /mnt/etc/resolv.conf
cp /etc/hosts /mnt/etc/hosts

mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /run /mnt/run
chroot /mnt

chown root:root /
chmod 755 /
passwd root
echo voidvm > /etc/hostname

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

GRUB_CFG="/etc/default/grub"
LINE="GRUB_ENABLE_CRYPTODISK=y"

echo "🔧 Configuring GRUB to enable cryptodisk support..."

# Check if the line already exists
if grep -q "^$LINE" "$GRUB_CFG"; then
  echo "✅ GRUB already has '$LINE'"
else
  # If line exists but is commented out — uncomment it
  if grep -q "^#\s*$LINE" "$GRUB_CFG"; then
    echo "🛠️  Uncommenting $LINE..."
    sed -i "s|^#\s*$LINE|$LINE|" "$GRUB_CFG"
  else
    # If it doesn't exist at all — append it
    echo "➕ Adding $LINE to $GRUB_CFG"
    echo "$LINE" >> "$GRUB_CFG"
  fi
fi

echo "✅ GRUB configuration updated."

GRUB_FILE="/etc/default/grub"
VG_NAME="voidvm"         # имя твоей volume group (как в примере)
LUKS_DEV=$SETUP_PART_ROOT     # или другой, если нужен
UUID=$(blkid -o value -s UUID "$LUKS_DEV")

echo "🔍 Found UUID for $LUKS_DEV: $UUID"

# Сформировать строку, которую нужно добавить
EXTRA_ARGS="rd.lvm.vg=${VG_NAME} rd.luks.uuid=${UUID}"

# Проверить, есть ли уже нужные аргументы
if grep -q "rd.luks.uuid=${UUID}" "$GRUB_FILE"; then
  echo "✅ GRUB_CMDLINE_LINUX_DEFAULT already contains LUKS and LVM options"
else
  echo "🛠️  Patching GRUB_CMDLINE_LINUX_DEFAULT..."

  # Заменим строку с GRUB_CMDLINE_LINUX_DEFAULT
  sed -i -E \
    "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\")(.*)\"|\1\2 ${EXTRA_ARGS}\"|" \
    "$GRUB_FILE"

  echo "✅ Updated GRUB_CMDLINE_LINUX_DEFAULT"
fi


dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
cryptsetup luksAddKey /dev/sda1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

#!/bin/bash
set -e

# You can parameterize this later
CRYPT_NAME="voidvm"
LUKS_DEV=$SETUP_PART_ROOT
KEYFILE="/boot/volume.key"
CRYPTTAB="/etc/crypttab"
DRACUT_CONF="/etc/dracut.conf.d/10-crypt.conf"

echo "🔐 Configuring /etc/crypttab for $CRYPT_NAME..."

# Ensure the keyfile exists
if [[ ! -f "$KEYFILE" ]]; then
  echo "❌ Keyfile $KEYFILE not found. Make sure to create it before continuing."
  exit 1
fi

# Add to /etc/crypttab (if not already present)
if grep -q "^$CRYPT_NAME" "$CRYPTTAB" 2>/dev/null; then
  echo "✅ Entry for $CRYPT_NAME already exists in $CRYPTTAB"
else
  echo "➕ Adding entry to $CRYPTTAB"
  echo "$CRYPT_NAME   $LUKS_DEV   $KEYFILE   luks" >> "$CRYPTTAB"
fi

# Create dracut config to include keyfile + crypttab
echo "⚙️  Creating $DRACUT_CONF"
echo 'install_items+=" /boot/volume.key /etc/crypttab "' > "$DRACUT_CONF"

echo "✅ Crypttab and dracut config ready."

# Optional: rebuild initramfs now
read -p "Do you want to rebuild initramfs now? (yes/[no]): " CONFIRM
if [[ "$CONFIRM" == "yes" ]]; then
  echo "🛠 Rebuilding initramfs..."
  dracut --force
  echo "✅ Initramfs rebuilt."
else
  echo "ℹ️ Skipping initramfs rebuild. Don’t forget to do it later."
fi


grub-install $SETUP_PART_EFI
xbps-reconfigure -fa
exit
umount -R /mnt

