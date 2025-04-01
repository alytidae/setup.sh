# Disk Partitioning Strategy

We use `parted` to partition the target disk.

## Layout

| Partition | Size     | Type     | Filesystem | Purpose       |
|-----------|----------|----------|------------|----------------|
| 1         | 512 MiB  | EFI      | FAT32      | Boot partition |
| 2         | rest     | Primary  | ext4/btrfs | Root system    |

## Why 1MiB offset?

We start at `1MiB` instead of `0` to ensure proper alignment for modern SSDs and GPT metadata safety.

This avoids performance issues and aligns with best practices recommended by `parted` and distro installers.

## Commands used

```bash
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 esp on \
  mkpart primary ext4 513MiB 100%
```
