## Setup Docker su RAID

### 1. Installa Docker

```bash
# Aggiorna sistema
sudo apt update
sudo apt upgrade -y

# Installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Aggiungi utente al gruppo docker
sudo usermod -aG docker ingenitor

# Ricarica gruppi (o fai logout/login)
newgrp docker

# Verifica installazione
docker --version
docker compose version
```

### 2. Ferma Docker (se già avviato)

```bash
sudo systemctl stop docker
sudo systemctl stop docker.socket
```

### 3. Crea la struttura directory sul RAID

```bash
# Crea directory Docker sul RAID
sudo mkdir -p /mnt/storage/docker/{data,volumes,containers}

# Imposta permessi corretti
sudo chown -R root:root /mnt/storage/docker
sudo chmod 755 /mnt/storage/docker
```

### 4. Configura Docker per usare il RAID

```bash
# Crea/modifica la configurazione daemon
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "data-root": "/mnt/storage/docker/data",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Verifica il contenuto
cat /etc/docker/daemon.json
```

### 5. Migra i dati esistenti (se esistono)

```bash
# Se Docker ha già dati su /var/lib/docker
if [ -d /var/lib/docker ]; then
  sudo rsync -av /var/lib/docker/ /mnt/storage/docker/data/
fi
```

### 6. Riavvia Docker

```bash
sudo systemctl start docker

# Verifica che usi la nuova posizione
sudo docker info | grep "Docker Root Dir"
# Dovrebbe mostrare: /mnt/storage/docker/data
```

## Organizza il progetto sul RAID

### Crea struttura per i progetti

```bash
# Struttura organizzata
# Clona i tuoi progetti qui
mkdir -p /mnt/storage/projects
cd /mnt/storage/projects
```

## Avvia i container

```bash
# Costruisci le immagini personalizzate
docker compose build

# Avvia tutti i servizi in background
# Traefik si occuperà del routing e della generazione automatica dei certificati SSL via Let's Encrypt
docker compose up -d
```

## Configurazione NextCloud

Entra nel container di NextCloud

```bash
docker exec -it --user www-data nextcloud-app bash
```

Esegui questi comandi nella shell del container di NextCloud

```bash
# Cache e Redis
php occ config:system:set memcache.local --value='\OC\Memcache\APCu'
php occ config:system:set memcache.distributed --value='\OC\Memcache\Redis'
php occ config:system:set memcache.locking --value='\OC\Memcache\Redis'
php occ config:system:set redis host --value='nextcloud-redis'
php occ config:system:set redis port --value=6379 --type=integer

# Preview di alta qualità
php occ config:system:set preview_max_x --value=2048 --type=integer
php occ config:system:set preview_max_y --value=2048 --type=integer
php occ config:system:set jpeg_quality --value=90 --type=integer

# Abilita preview per vari formati
php occ config:system:set enabledPreviewProviders 0 --value='OC\Preview\PNG'
php occ config:system:set enabledPreviewProviders 1 --value='OC\Preview\JPEG'
php occ config:system:set enabledPreviewProviders 2 --value='OC\Preview\GIF'
php occ config:system:set enabledPreviewProviders 3 --value='OC\Preview\BMP'
php occ config:system:set enabledPreviewProviders 4 --value='OC\Preview\HEIC'
php occ config:system:set enabledPreviewProviders 5 --value='OC\Preview\MP3'
php occ config:system:set enabledPreviewProviders 6 --value='OC\Preview\TXT'
php occ config:system:set enabledPreviewProviders 7 --value='OC\Preview\MarkDown'
php occ config:system:set enabledPreviewProviders 8 --value='OC\Preview\PDF'

# Finestra manutenzione
php occ config:system:set maintenance_window_start --value=3 --type=integer

# Italia
php occ config:system:set default_phone_region --value='IT'

exit
```

Riavvia il container di NextCloud per apportare le modifiche

```bash
docker compose restart nextcloud
```
