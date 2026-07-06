# Guida: Ubuntu Server su microSD + RAID 1 NVMe Storage

## Raspberry Pi 5 con Pimoroni NVMe Base Duo

## Architettura

- **Boot**: microSD (sistema operativo)
- **Storage**: RAID 1 su due NVMe (dati)
- **Accesso**: SSH con password, utente `ingenitor` superuser
- **Rete**: IP statico `192.168.1.20`

## Prerequisiti

- Ubuntu Server già scritto su microSD con dd
- Raspberry Pi 5 avviato da USB
- Due NVMe installati nell'HAT Pimoroni
- Accesso SSH alla USB

## Fase 1: Configurazione della microSD (Prima del Primo Boot)

### 1.0 Installazione del sistema operativo

```bash
cd /tmp
wget -O ubuntu-raspi.img.xz "https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.3-preinstalled-server-arm64+raspi.img.xz"
sudo xzcat /tmp/ubuntu-raspi.img.xz | sudo dd of=/dev/mmcblk0 bs=4M status=progress conv=fsync
sync
```

### 1.1 Monta la partizione root della microSD

```bash
sudo mkdir -p /mnt/sd
sudo mount /dev/mmcblk0p2 /mnt/sd
sudo mkdir -p /mnt/sdboot
sudo mount /dev/mmcblk0p1 /mnt/sdboot
```

### 1.2 Crea l'utente `ingenitor` superuser

```bash
# Prepara il chroot
sudo mount --bind /dev /mnt/sd/dev
sudo mount --bind /proc /mnt/sd/proc
sudo mount --bind /sys /mnt/sd/sys
sudo mount --bind /run /mnt/sd/run

# Entra nel sistema sulla microSD
sudo chroot /mnt/sd

# Crea l'utente ingenitor
adduser ingenitor
# Inserisci la password quando richiesto

# Aggiungi ai gruppi necessari (incluso sudo)
usermod -aG sudo,adm,dialout,cdrom,audio,video,plugdev,netdev,lxd ingenitor

# Verifica
groups ingenitor
```

### 1.3 Configura IP statico (192.168.1.20)

```bash
# Ancora dentro il chroot
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

# Verifica
cat /etc/netplan/50-static-ip.yaml
```

### 1.4 Abilita SSH con autenticazione password

Controlla che in `/etc/ssh/sshd_config` ci sia questa riga `Include /etc/ssh/sshd_config.d/*.conf`. Altrimenti inseriscila.

```bash
# Ancora dentro il chroot

sudo tee /etc/ssh/sshd_config.d/50-cloud-init.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication yes
EOF
```

### 1.5 Installa mdadm e strumenti necessari

```bash
# Ancora dentro il chroot
apt update
apt install -y mdadm nvme-cli
```

### 1.6 Esci dal chroot e smonta

```bash
# Esci dal chroot
exit

# Smonta tutto
sudo umount /mnt/sd/run
sudo umount /mnt/sd/dev
sudo umount /mnt/sd/proc
sudo umount /mnt/sd/sys
sudo umount /mnt/sd
sudo umount /mnt/sdboot
```

## Fase 2: Primo Boot dalla microSD

### 2.1 Spegni il sistema

```bash
sudo shutdown -h now
```

### 2.2 Rimuovi la chiavetta USB

### 2.3 Accendi il Raspberry Pi

Dovrebbe avviarsi dalla microSD.

### 2.4 Connettiti via SSH

```bash
ssh ingenitor@192.168.1.20
```

**Nota:** Se al primo boot Ubuntu chiede di cambiare la password per l'utente `ubuntu`, puoi ignorarlo e loggarti direttamente con `ingenitor`.

## Fase 3: Creazione del RAID 1 sui NVMe

### 3.1 Verifica i dispositivi NVMe

```bash
lsblk
```

Dovresti vedere:

- `nvme0n1` - 238.5G
- `nvme1n1` - 238.5G

### 3.2 Pulisci i dischi NVMe

```bash
# Pulisci eventuali metadata esistenti
sudo wipefs -a /dev/nvme0n1
sudo wipefs -a /dev/nvme1n1
sudo mdadm --zero-superblock /dev/nvme0n1 2>/dev/null || true
sudo mdadm --zero-superblock /dev/nvme1n1 2>/dev/null || true
```

### 3.3 Crea le partizioni GPT su entrambi i dischi

**Primo NVMe:**

```bash
sudo gdisk /dev/nvme0n1
```

Comandi in gdisk:

- `o` (crea nuova tabella GPT vuota)
- `n` (nuova partizione)
  - Partition number: `1` (Invio)
  - First sector: (Invio per default)
  - Last sector: (Invio per usare tutto lo spazio)
  - Hex code: `fd00` (Linux RAID)
- `w` (scrivi le modifiche)
- `y` (conferma)

**Secondo NVMe:**

```bash
sudo gdisk /dev/nvme1n1
```

Ripeti gli stessi comandi.

### 3.4 Crea l'array RAID 1

```bash
sudo mdadm --create /dev/md/storage --level=1 --raid-devices=2 --metadata=1.2 /dev/nvme0n1p1 /dev/nvme1n1p1
```

Quando chiede il write-intent bitmap, rispondi: `y`

### 3.5 Verifica il RAID

```bash
watch cat /proc/mdstat
```

Vedrai la sincronizzazione in corso. Puoi continuare mentre sincronizza.

### 3.6 Formatta il RAID con ext4

```bash
sudo mkfs.ext4 -L STORAGE /dev/md/storage
```

### 3.7 Ottieni l'UUID del RAID

```bash
sudo blkid /dev/md/storage
```

**Annota l'UUID!** Esempio: `12345678-abcd-1234-5678-123456789abc`

## Fase 4: Monta Automaticamente il RAID al Boot

### 4.1 Crea il punto di mount

```bash
sudo mkdir -p /mnt/storage
```

### 4.2 Configura fstab per il mount automatico

```bash
# Ottieni l'UUID
UUID_STORAGE=$(sudo blkid -s UUID -o value /dev/md/storage)

# Aggiungi al fstab
echo "UUID=$UUID_STORAGE  /mnt/storage  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab

# Verifica
cat /etc/fstab
```

**Nota:** `nofail` permette al sistema di avviarsi anche se il RAID non è disponibile.

### 4.3 Configura mdadm.conf

```bash
# Genera la configurazione RAID
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# Verifica
cat /etc/mdadm/mdadm.conf
```

### 4.4 Aggiorna initramfs

```bash
sudo update-initramfs -u -k all
```

### 4.5 Monta subito il RAID

```bash
sudo mount -a
df -h
```

Dovresti vedere `/mnt/storage` montato con ~238GB disponibili.

## Fase 5: Configurazione dei Permessi Storage

### 5.1 Cambia proprietà della directory storage

```bash
# Rendi ingenitor proprietario dello storage
sudo chown -R ingenitor:ingenitor /mnt/storage

# Verifica
ls -la /mnt/storage
```

### 5.2 Test di scrittura

```bash
# Crea un file di test
echo "RAID 1 funziona!" > /mnt/storage/test.txt
cat /mnt/storage/test.txt
```

### 6 Notifiche via Telegram

**Setup:**

1. Crea un bot Telegram:

   - Parla con [@BotFather](https://t.me/botfather) su Telegram
   - Usa `/newbot` e segui le istruzioni
   - Ottieni il **TOKEN** del bot

2. Ottieni il tuo **CHAT_ID**:

   - Parla con [@userinfobot](https://t.me/userinfobot)
   - Ti darà il tuo CHAT_ID

3. Installa lo script di notifica:

```bash
# Crea script notifiche Telegram
sudo tee /usr/local/bin/raid-notify-telegram.sh > /dev/null <<'EOF'
#!/bin/bash
BOT_TOKEN="IL_TUO_TOKEN_QUI"
CHAT_ID="IL_TUO_CHAT_ID_QUI"

EVENT="$1"        # es: RebuildStarted, Fail, DegradedArray...
DEVICE="$2"       # mdadm passa spesso anche il device come $2, es /dev/md127
MD_NAME=$(basename "$DEVICE" 2>/dev/null)

# Se abbiamo un device valido, controlliamo l'azione reale in corso
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

# Configura mdadm per usare lo script
sudo nano /etc/mdadm/mdadm.conf
```

Aggiungi/modifica questa riga:

```
PROGRAM /usr/local/bin/raid-notify-telegram.sh
```

Riavvia mdmonitor:

```bash
sudo systemctl restart mdmonitor.service
```

**Test:**

```bash
# Simula un alert
echo "Test" | /usr/local/bin/raid-notify-telegram.sh "RAID Test Alert"
```

Dovresti ricevere un messaggio su Telegram! 🎉

## Test del sistema di notifica

Dopo aver configurato una delle opzioni sopra:

```bash
# Simula un guasto (sostituisci /dev/md/storage con il nome effettivo, es. /dev/md127 se necessario)
# Dovresti ricevere la notifica
sudo mdadm /dev/md/storage --fail /dev/nvme0n1p1

# Aspetta qualche secondo
sleep 5

# Controlla i log
sudo journalctl -u mdmonitor.service -n 20

# Ripristina
sudo mdadm /dev/md/storage --remove /dev/nvme0n1p1
sudo mdadm /dev/md/storage --add /dev/nvme0n1p1
```

# Comandi Utili per Gestione RAID

### Verificare stato RAID

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md/storage
watch cat /proc/mdstat  # monitoraggio in tempo reale
```

### Simulare un guasto del disco

```bash
sudo mdadm /dev/md/storage --fail /dev/nvme0n1p1
```

### Rimuovere disco guasto

```bash
sudo mdadm /dev/md/storage --remove /dev/nvme0n1p1
```

### Aggiungere disco sostitutivo

```bash
# Dopo aver partizionato il nuovo disco
sudo mdadm /dev/md/storage --add /dev/nvme0n1p1
```

### Fermare il RAID (per manutenzione)

```bash
sudo umount /mnt/storage
sudo mdadm --stop /dev/md/storage
```

### Riassemblare il RAID

```bash
sudo mdadm --assemble /dev/md/storage /dev/nvme0n1p1 /dev/nvme1n1p1
sudo mount /mnt/storage
```

## Struttura Directory Suggerita per Storage

```bash
# Crea directory organizzate
mkdir -p /mnt/storage/{documents,media,backups,downloads,projects}

# Imposta permessi
sudo chown -R ingenitor:ingenitor /mnt/storage
```

## Monitoraggio Salute NVMe

### Verifica temperatura e salute

```bash
sudo nvme smart-log /dev/nvme0n1
sudo nvme smart-log /dev/nvme1n1
```

### Verifica errori

```bash
sudo nvme error-log /dev/nvme0n1
sudo nvme error-log /dev/nvme1n1
```

## Backup della Configurazione

### Backup mdadm.conf

```bash
sudo cp /etc/mdadm/mdadm.conf /mnt/storage/backups/mdadm.conf.backup
```

### Backup fstab

```bash
sudo cp /etc/fstab /mnt/storage/backups/fstab.backup
```

## Risoluzione Problemi

### RAID non si monta al boot

```bash
# Verifica mdadm.conf
cat /etc/mdadm/mdadm.conf

# Riassembla manualmente
sudo mdadm --assemble --scan
sudo mount /mnt/storage
```

### Uno o entrambi i dischi non vengono rilevati

```bash
# Verifica dispositivi PCIe
lspci | grep -i nvme

# Controlla log kernel
sudo dmesg | grep -i nvme

# Rescan bus PCIe
echo 1 | sudo tee /sys/bus/pci/rescan
```

### Sincronizzazione RAID lenta

```bash
# Aumenta velocità rebuild (temporaneamente)
echo 200000 | sudo tee /proc/sys/dev/raid/speed_limit_min
echo 400000 | sudo tee /proc/sys/dev/raid/speed_limit_max
```

### Controllare prestazioni storage

```bash
# Test velocità scrittura
sudo dd if=/dev/zero of=/mnt/storage/test.img bs=1M count=1024 conv=fdatasync

# Test velocità lettura
sudo dd if=/mnt/storage/test.img of=/dev/null bs=1M

# Pulizia
rm /mnt/storage/test.img
```
