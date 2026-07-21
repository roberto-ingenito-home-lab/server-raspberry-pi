## Setup Docker on RAID

### 1. Install Docker

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker ingenitor

# Reload groups (or logout/login)
newgrp docker

# Verify installation
docker --version
docker compose version
```

### 2. Stop Docker (if already running)

```bash
sudo systemctl stop docker
sudo systemctl stop docker.socket
```

### 3. Create directory structure on RAID

```bash
# Create Docker directory on RAID
sudo mkdir -p /mnt/storage/docker/{data,volumes,containers}

# Set correct permissions
sudo chown -R root:root /mnt/storage/docker
sudo chmod 755 /mnt/storage/docker
```

### 4. Configure Docker to use RAID

```bash
# Create/modify daemon configuration
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

# Verify content
cat /etc/docker/daemon.json
```

### 5. Migrate existing data (if any)

```bash
# If Docker already has data in /var/lib/docker
if [ -d /var/lib/docker ]; then
  sudo rsync -av /var/lib/docker/ /mnt/storage/docker/data/
fi
```

### 6. Restart Docker

```bash
sudo systemctl start docker

# Verify it uses the new location
sudo docker info | grep "Docker Root Dir"
# Should show: /mnt/storage/docker/data
```

## Organize project on RAID

### Create structure for projects

```bash
# Organized structure
# Clone your projects here
mkdir -p /mnt/storage/projects
cd /mnt/storage/projects
```

## Start containers

```bash
# Build custom images
docker compose build

# Start all services in background
# Cloudflare tunnel (cloudflared) will handle secure routing of subdomains
docker compose up -d
```

## NextCloud Configuration

Enter the NextCloud container

```bash
docker exec -it --user www-data nextcloud-app bash
```

Run these commands in the NextCloud container shell

```bash
# Cache and Redis
php occ config:system:set memcache.local --value='\OC\Memcache\APCu'
php occ config:system:set memcache.distributed --value='\OC\Memcache\Redis'
php occ config:system:set memcache.locking --value='\OC\Memcache\Redis'
php occ config:system:set redis host --value='nextcloud-redis'
php occ config:system:set redis port --value=6379 --type=integer

# High quality preview
php occ config:system:set preview_max_x --value=2048 --type=integer
php occ config:system:set preview_max_y --value=2048 --type=integer
php occ config:system:set jpeg_quality --value=90 --type=integer

# Enable preview for various formats
php occ config:system:set enabledPreviewProviders 0 --value='OC\Preview\PNG'
php occ config:system:set enabledPreviewProviders 1 --value='OC\Preview\JPEG'
php occ config:system:set enabledPreviewProviders 2 --value='OC\Preview\GIF'
php occ config:system:set enabledPreviewProviders 3 --value='OC\Preview\BMP'
php occ config:system:set enabledPreviewProviders 4 --value='OC\Preview\HEIC'
php occ config:system:set enabledPreviewProviders 5 --value='OC\Preview\MP3'
php occ config:system:set enabledPreviewProviders 6 --value='OC\Preview\TXT'
php occ config:system:set enabledPreviewProviders 7 --value='OC\Preview\MarkDown'
php occ config:system:set enabledPreviewProviders 8 --value='OC\Preview\PDF'

# Maintenance window
php occ config:system:set maintenance_window_start --value=3 --type=integer

# Italy
php occ config:system:set default_phone_region --value='IT'

exit
```

Restart the NextCloud container to apply changes

```bash
docker compose restart nextcloud
```
