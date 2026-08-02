# Guide: Ubuntu Server on microSD + RAID 1 NVMe Storage

## Raspberry Pi 5 with Pimoroni NVMe Base Duo

## Architecture

- **Boot**: microSD (operating system)
- **Storage**: RAID 1 on two NVMes (data)
- **Access**: SSH with password, `ingenitor` superuser
- **Network**: Static IP `192.168.1.20`

## Prerequisites

- Ubuntu Server already written to microSD with dd
- Raspberry Pi 5 booted from USB
- Two NVMes installed in the Pimoroni HAT
- SSH access to the USB

## Phase 1: MicroSD Configuration (Before First Boot)

### 1.0 Operating system installation

```bash
cd /tmp
wget -O ubuntu-raspi.img.xz "https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.3-preinstalled-server-arm64+raspi.img.xz"
sudo xzcat /tmp/ubuntu-raspi.img.xz | sudo dd of=/dev/mmcblk0 bs=4M status=progress conv=fsync
sync
```

### 1.1 Mount the microSD root partition

```bash
sudo mkdir -p /mnt/sd
sudo mount /dev/mmcblk0p2 /mnt/sd
sudo mkdir -p /mnt/sdboot
sudo mount /dev/mmcblk0p1 /mnt/sdboot
```

### 1.2 Create the `ingenitor` superuser

```bash
# Prepare chroot
sudo mount --bind /dev /mnt/sd/dev
sudo mount --bind /proc /mnt/sd/proc
sudo mount --bind /sys /mnt/sd/sys
sudo mount --bind /run /mnt/sd/run

# Enter the system on the microSD
sudo chroot /mnt/sd

# Create the ingenitor user
adduser ingenitor
# Enter password when prompted

# Add to necessary groups (including sudo)
usermod -aG sudo,adm,dialout,cdrom,audio,video,plugdev,netdev,lxd ingenitor

# Verify
groups ingenitor
```

### 1.3 Configure static IP (192.168.1.20)

```bash
# Still inside the chroot
cat > /etc/netplan/50-static-ip.yaml <<'EOF'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.20/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

# Verify
cat /etc/netplan/50-static-ip.yaml
```

### 1.4 Enable SSH with password authentication

Check that `/etc/ssh/sshd_config` contains this line `Include /etc/ssh/sshd_config.d/*.conf`. Otherwise, insert it.

```bash
# Still inside the chroot

sudo tee /etc/ssh/sshd_config.d/50-cloud-init.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication yes
EOF
```

### 1.5 Install mdadm and necessary tools

```bash
# Still inside the chroot
apt update
apt install -y mdadm nvme-cli
```

### 1.6 Exit chroot and unmount

```bash
# Exit chroot
exit

# Unmount everything
sudo umount /mnt/sd/run
sudo umount /mnt/sd/dev
sudo umount /mnt/sd/proc
sudo umount /mnt/sd/sys
sudo umount /mnt/sd
sudo umount /mnt/sdboot
```

## Phase 2: First Boot from microSD

### 2.1 Shut down the system

```bash
sudo shutdown -h now
```

### 2.2 Remove the USB drive

### 2.3 Turn on the Raspberry Pi

It should boot from the microSD.

### 2.4 Connect via SSH

```bash
ssh ingenitor@192.168.1.20
```

**Note:** If on the first boot Ubuntu asks to change the password for the `ubuntu` user, you can ignore it and log in directly with `ingenitor`.

## Phase 3: RAID 1 Creation on NVMes

### 3.1 Verify NVMe devices

```bash
lsblk
```

You should see:

- `nvme0n1` - 238.5G
- `nvme1n1` - 238.5G

### 3.2 Wipe the NVMe disks

```bash
# Wipe any existing metadata
sudo wipefs -a /dev/nvme0n1
sudo wipefs -a /dev/nvme1n1
sudo mdadm --zero-superblock /dev/nvme0n1 2>/dev/null || true
sudo mdadm --zero-superblock /dev/nvme1n1 2>/dev/null || true
```

### 3.3 Create GPT partitions on both disks

**First NVMe:**

```bash
sudo gdisk /dev/nvme0n1
```

Commands in gdisk:

- `o` (create new empty GPT table)
- `n` (new partition)
  - Partition number: `1` (Enter)
  - First sector: (Enter for default)
  - Last sector: (Enter to use all space)
  - Hex code: `fd00` (Linux RAID)
- `w` (write changes)
- `y` (confirm)

**Second NVMe:**

```bash
sudo gdisk /dev/nvme1n1
```

Repeat the same commands.

### 3.4 Create the RAID 1 array

```bash
sudo mdadm --create /dev/md/storage --level=1 --raid-devices=2 --metadata=1.2 /dev/nvme0n1p1 /dev/nvme1n1p1
```

When asked for the write-intent bitmap, answer: `y`

### 3.5 Verify the RAID

```bash
watch cat /proc/mdstat
```

You will see the synchronization in progress. You can continue while it syncs.

### 3.6 Format the RAID with ext4

```bash
sudo mkfs.ext4 -L STORAGE /dev/md/storage
```

### 3.7 Get the RAID UUID

```bash
sudo blkid /dev/md/storage
```

**Write down the UUID!** Example: `12345678-abcd-1234-5678-123456789abc`

## Phase 4: Automatically Mount the RAID at Boot

### 4.1 Create the mount point

```bash
sudo mkdir -p /mnt/storage
```

### 4.2 Configure fstab for automatic mount

```bash
# Get the UUID
UUID_STORAGE=$(sudo blkid -s UUID -o value /dev/md/storage)

# Add to fstab
echo "UUID=$UUID_STORAGE  /mnt/storage  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab

# Verify
cat /etc/fstab
```

**Note:** `nofail` allows the system to boot even if the RAID is not available.

### 4.3 Configure mdadm.conf

```bash
# Generate RAID configuration
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# Verify
cat /etc/mdadm/mdadm.conf
```

### 4.4 Update initramfs

```bash
sudo update-initramfs -u -k all
```

### 4.5 Mount the RAID immediately

```bash
sudo mount -a
df -h
```

You should see `/mnt/storage` mounted with ~238GB available.

## Phase 5: Storage Permissions Configuration

### 5.1 Change ownership of the storage directory

```bash
# Make ingenitor the owner of the storage
sudo chown -R ingenitor:ingenitor /mnt/storage

# Verify
ls -la /mnt/storage
```

### 5.2 Write test

```bash
# Create a test file
echo "RAID 1 funziona!" > /mnt/storage/test.txt
cat /mnt/storage/test.txt
```

### 6 Telegram Notifications

**Setup:**

1. Create a Telegram bot:

   - Talk to [@BotFather](https://t.me/botfather) on Telegram
   - Use `/newbot` and follow instructions
   - Get the bot **TOKEN**

2. Get your **CHAT_ID**:

   - Talk to [@userinfobot](https://t.me/userinfobot)
   - It will give you your CHAT_ID

3. Install the notification script:

```bash
# Create Telegram notifications script
sudo tee /usr/local/bin/raid-notify-telegram.sh > /dev/null <<'EOF'
#!/bin/bash
BOT_TOKEN="IL_TUO_TOKEN_QUI"
CHAT_ID="IL_TUO_CHAT_ID_QUI"

EVENT="$1"        # e.g.: RebuildStarted, Fail, DegradedArray...
DEVICE="$2"       # mdadm often passes the device as well as $2, e.g. /dev/md127
MD_NAME=$(basename "$DEVICE" 2>/dev/null)

# If we have a valid device, check the actual action in progress
ACTION=""
if [ -n "$MD_NAME" ] && [ -f "/sys/block/$MD_NAME/md/sync_action" ]; then
    ACTION=$(cat "/sys/block/$MD_NAME/md/sync_action")
fi

case "$EVENT" in
  RebuildStarted)
    if [ "$ACTION" = "check" ]; then
      LABEL="🔍 Monthly consistency check started (routine, read-only)"
    elif [ "$ACTION" = "recover" ]; then
      LABEL="🚨 REBUILD started — a disk is being rebuilt, array was degraded!"
    else
      LABEL="⚠️ Rebuild/check started (action: ${ACTION:-unknown})"
    fi
    ;;
  RebuildFinished)
    LABEL="✅ Rebuild/check finished"
    ;;
  Fail)
    LABEL="🔴 DISK FAILURE detected"
    ;;
  DegradedArray)
    LABEL="🟠 Array is DEGRADED"
    ;;
  *)
    LABEL="$EVENT"
    ;;
esac

MESSAGE="RAID Alert on $(hostname) [$DEVICE]: $LABEL"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="${MESSAGE}" \
  > /dev/null
EOF

sudo chmod +x /usr/local/bin/raid-notify-telegram.sh

# Configure mdadm to use the script
sudo nano /etc/mdadm/mdadm.conf
```

Add/modify this line:

```
PROGRAM /usr/local/bin/raid-notify-telegram.sh
```

Restart mdmonitor:

```bash
sudo systemctl restart mdmonitor.service
```

**Test:**

```bash
# Simulate an alert
echo "Test" | /usr/local/bin/raid-notify-telegram.sh "RAID Test Alert"
```

You should receive a message on Telegram! 🎉

## Notification System Test

After configuring one of the options above:

```bash
# Simulate a failure (replace /dev/md/storage with actual name, e.g. /dev/md127 if necessary)
# You should receive the notification
sudo mdadm /dev/md/storage --fail /dev/nvme0n1p1

# Wait a few seconds
sleep 5

# Check logs
sudo journalctl -u mdmonitor.service -n 20

# Restore
sudo mdadm /dev/md/storage --remove /dev/nvme0n1p1
sudo mdadm /dev/md/storage --add /dev/nvme0n1p1
```

# Useful Commands for RAID Management

### Check RAID status

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md/storage
watch cat /proc/mdstat  # real-time monitoring
```

### Simulate disk failure

```bash
sudo mdadm /dev/md/storage --fail /dev/nvme0n1p1
```

### Remove failed disk

```bash
sudo mdadm /dev/md/storage --remove /dev/nvme0n1p1
```

### Add replacement disk

```bash
# After partitioning the new disk
sudo mdadm /dev/md/storage --add /dev/nvme0n1p1
```

### Stop RAID (for maintenance)

```bash
sudo umount /mnt/storage
sudo mdadm --stop /dev/md/storage
```

### Reassemble RAID

```bash
sudo mdadm --assemble /dev/md/storage /dev/nvme0n1p1 /dev/nvme1n1p1
sudo mount /mnt/storage
```

## Suggested Directory Structure for Storage

```bash
# Create organized directories
mkdir -p /mnt/storage/{documents,media,backups,downloads,projects}

# Set permissions
sudo chown -R ingenitor:ingenitor /mnt/storage
```

## NVMe Health Monitoring

### Check temperature and health

```bash
sudo nvme smart-log /dev/nvme0n1
sudo nvme smart-log /dev/nvme1n1
```

### Check errors

```bash
sudo nvme error-log /dev/nvme0n1
sudo nvme error-log /dev/nvme1n1
```

## Configuration Backup

### Backup mdadm.conf

```bash
sudo cp /etc/mdadm/mdadm.conf /mnt/storage/backups/mdadm.conf.backup
```

### Backup fstab

```bash
sudo cp /etc/fstab /mnt/storage/backups/fstab.backup
```

## Troubleshooting

### RAID does not mount at boot

```bash
# Verify mdadm.conf
cat /etc/mdadm/mdadm.conf

# Reassemble manually
sudo mdadm --assemble --scan
sudo mount /mnt/storage
```

### One or both disks are not detected

```bash
# Verify PCIe devices
lspci | grep -i nvme

# Check kernel logs
sudo dmesg | grep -i nvme

# Rescan PCIe bus
echo 1 | sudo tee /sys/bus/pci/rescan
```

### Slow RAID synchronization

```bash
# Increase rebuild speed (temporarily)
echo 200000 | sudo tee /proc/sys/dev/raid/speed_limit_min
echo 400000 | sudo tee /proc/sys/dev/raid/speed_limit_max
```

### Check storage performance

```bash
# Write speed test
sudo dd if=/dev/zero of=/mnt/storage/test.img bs=1M count=1024 conv=fdatasync

# Read speed test
sudo dd if=/mnt/storage/test.img of=/dev/null bs=1M

# Cleanup
rm /mnt/storage/test.img
```

## NVMe RAID Stability & Monthly Scrub Fix (Raspberry Pi 5)

To prevent NVMe controllers from dropping off the PCIe bus or crashing during the monthly `mdadm` data check (`mdcheck` / `checkarray`), apply the following stability tweaks:

### 1. Disable NVMe Autonomous Power State Transitions (APST)
NVMe power management causes controller reset failures under prolonged IO scrub on Raspberry Pi PCIe HATs.

Edit `/boot/firmware/cmdline.txt` (or `/boot/cmdline.txt`) and append:
```text
nvme_core.default_ps_max_latency_us=0
```

### 2. Limit RAID Data Check Speed Limit
Prevent thermal throttling and power spikes during background scrub operations:

Create `/etc/sysctl.d/99-raid-speed.conf`:
```ini
dev.raid.speed_limit_min = 1000
dev.raid.speed_limit_max = 50000
```
Apply with:
```bash
sudo sysctl -p /etc/sysctl.d/99-raid-speed.conf
```

### 3. Re-adding a Failed NVMe Disk after Reboot
If an NVMe dropped due to reset failure (`CSTS=0x1` / `FLR timeout`):
```bash
# After reboot:
sudo mdadm /dev/md127 --remove failed
sudo mdadm /dev/md127 --add /dev/nvme1n1
```

