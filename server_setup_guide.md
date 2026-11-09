# 🗺️ Guida Principale di Setup del Server (Step-by-Step)

Questo documento rappresenta il **punto di ingresso principale (Master Playbook)** per configurare da zero l'intero server domestico su **Raspberry Pi 5**.

Il percorso è strutturato in **ordine cronologico rigoroso**, rimandando una alla volta alle guide specifiche presenti nel repository e integrando tutti i passaggi tecnici, i prerequisiti e le configurazioni che non sono documentati nei singoli file dedicati.

---

## 📋 Indice del Percorso di Setup

1. [**Step 1 — Sistema Operativo, Rete Statica e Storage RAID 1 NVMe**](#step-1--sistema-operativo-rete-statica-e-storage-raid-1-nvme)
2. [**Step 2 — Sicurezza SSH e Protezione Brute-Force (Fail2ban)**](#step-2--sicurezza-ssh-e-protezione-brute-force-fail2ban)
3. [**Step 3 — Installazione di Docker sul Volume RAID 1**](#step-3--installazione-di-docker-sul-volume-raid-1)
4. [**Step 4 — Preparazione Ambiente Docker, GHCR, Volumi e Cartelle Host**](#step-4--preparazione-ambiente-docker-ghcr-volumi-e-cartelle-host-non-documentato-altrove) *(Non documentato nelle altre guide)*
5. [**Step 5 — Configurazione Variabili d'Ambiente (`.env`) e SMTP**](#step-5--configurazione-variabili-dambiente-env-e-smtp)
6. [**Step 6 — Avvio dello Stack Docker e Post-Configurazione Nextcloud**](#step-6--avvio-dello-stack-docker-e-post-configurazione-nextcloud)
7. [**Step 7 — Cloudflare Tunnel, Routing, Watchtower CI/CD, SEO e SSH Remoto**](#step-7--cloudflare-tunnel-routing-watchtower-cicd-seo-e-ssh-remoto)
8. [**Step 8 — Backup Automatici dei Database e Persistenza Dati**](#step-8--backup-automatici-dei-database-e-persistenza-dati)
9. [**Step 9 — Manutenzione Periodica e Ottimizzazione Spazio (Server & WSL2)**](#step-9--manutenzione-periodica-e-ottimizzazione-spazio-server--wsl2)

---

## Step 1 — Sistema Operativo, Rete Statica e Storage RAID 1 NVMe

In questa prima fase si installa Ubuntu Server 24.04 ARM64 sulla microSD, si configura la rete locale con IP statico e si crea il volume ridondante RAID 1 sui due dischi NVMe collegati al **Pimoroni NVMe Base Duo**.

👉 **Guida da seguire:** [**`guides/RAID_configuration.md`**](guides/RAID_configuration.md)  
*(Riferimento aggiuntivo per il solo IP statico Netplan: [**`guides/raspberry_pi_infrastructure.md`**](guides/raspberry_pi_infrastructure.md))*

### Ordine di esecuzione dentro la guida:
1. **Phase 1 & Phase 2 (`RAID_configuration.md`)**:
   - Flash di Ubuntu Server su microSD e configurazione in `chroot`: creazione superuser `ingenitor`, impostazione IP statico `192.168.1.100/24` tramite Netplan (approfondito anche in [`guides/raspberry_pi_infrastructure.md`](guides/raspberry_pi_infrastructure.md)), abilitazione SSH, configurazione **chiavi SSH ED25519** (`~/.ssh/authorized_keys`) e installazione di `mdadm` e `nvme-cli`.
   - Spegnimento, rimozione dell'unità USB di avvio temporanea e primo boot da microSD.
2. **Phase 3, Phase 4 & Phase 5 (`RAID_configuration.md`)**:
   - Pulizia (`wipefs`) e partizionamento GPT (`gdisk`, tipo `fd00`) dei dischi `/dev/nvme0n1` e `/dev/nvme1n1`.
   - Creazione dell'array RAID 1 `/dev/md/storage` con write-intent bitmap attiva.
   - Formattazione in `ext4`, mount automatico all'avvio su `/mnt/storage` tramite `/etc/fstab` (con flag `nofail`), salvataggio in `/etc/mdadm/mdadm.conf`, aggiornamento `initramfs` e assegnazione permessi a `ingenitor:ingenitor`.
3. **Phase 6 — Notifiche Telegram (`RAID_configuration.md`)**:
   - Creazione del bot Telegram e installazione dello script `/usr/local/bin/raid-notify-telegram.sh` agganciato a `mdmonitor.service` per ricevere avvisi in tempo reale in caso di degrado o rebuild del RAID.
4. **Fix Stabilità NVMe & Scrub Mensile (`RAID_configuration.md` — sezione finale)**:
   - **Importante sul Raspberry Pi 5**: Applicare subito le due modifiche preventive descritte a fine guida per evitare che il controllo mensile (`mdcheck_start.timer`) saturi il bus PCIe causando il drop di un disco:
     - Aggiunta di `nvme_core.default_ps_max_latency_us=0 nvme_core.io_timeout=120` a `/boot/firmware/cmdline.txt`.
     - Limitazione della velocità di rebuild/scrub a 50 MB/s in `/etc/sysctl.d/99-mdadm-speed.conf`.

---

## Step 2 — Sicurezza SSH e Protezione Brute-Force (Fail2ban)

Con il sistema operativo e la rete attivi, prima di installare i servizi o aprire porte sul router, metti in sicurezza il demone SSH contro tentativi di accesso non autorizzati.

👉 **Guida da seguire:** [**`guides/fail2ban_guide.md`**](guides/fail2ban_guide.md)

### Cosa fare:
1. Installa il pacchetto `fail2ban`.
2. Crea il file `/etc/fail2ban/jail.local` (non modificare mai `jail.conf` direttamente) e attiva la jail `[sshd]` sulla porta `22` (`maxretry = 5`, `findtime = 10m`, `bantime = 1h`).
3. Abilita e riavvia il servizio `fail2ban` con `systemctl`.

---

## Step 3 — Installazione di Docker sul Volume RAID 1

Ora che `/mnt/storage` è montato sul RAID 1 NVMe, installa Docker configurandolo per salvare immagini, volumi e container sul RAID anziché sulla microSD di boot.

👉 **Guida da seguire:** [**`guides/docker_RAID_configuration.md`**](guides/docker_RAID_configuration.md) *(⚠️ **Solo la sezione "Setup Docker on RAID", punti 1–6**)*

### Cosa fare:
1. Esegui i punti da **1 a 6** di [`guides/docker_RAID_configuration.md`](guides/docker_RAID_configuration.md):
   - Installazione di Docker Engine e Docker Compose tramite script ufficiale.
   - Aggiunta dell'utente `ingenitor` al gruppo `docker`.
   - Creazione di `/mnt/storage/docker/{data,volumes,containers}`.
   - Configurazione di `/etc/docker/daemon.json` con `"data-root": "/mnt/storage/docker/data"` e rotazione dei log (`max-size: 10m`, `max-file: 3`).
   - Riavvio di Docker e verifica con `sudo docker info | grep "Docker Root Dir"`.
2. 🛑 **Fermati prima della sezione *"Start containers"*** di quella guida: prima di poter avviare `docker compose up -d`, devi completare gli **Step 4 e 5** qui sotto!

---

## Step 4 — Preparazione Ambiente Docker, GHCR, Volumi e Cartelle Host *(Non documentato altrove)*

Questo step raccoglie i prerequisiti strutturali richiesti dai file [`docker-compose.yml`](docker-compose.yml) e [`compose/*.yml`](compose/) che **non sono documentati nelle altre guide**, ma senza i quali il primo avvio di Docker Compose fallirebbe.

### 4.1 Clonazione del Repository sul RAID

Come previsto dall'organizzazione su RAID ([`guides/docker_RAID_configuration.md`](guides/docker_RAID_configuration.md)), clona il repository nella cartella `/mnt/storage/projects/`:

```bash
mkdir -p /mnt/storage/projects
cd /mnt/storage/projects
git clone https://github.com/roberto-ingenito-home-lab/server-raspberry-pi.git
cd /mnt/storage/projects/server-raspberry-pi
```

### 4.2 Autenticazione a GitHub Container Registry (`ghcr.io`)

Molte applicazioni dello stack (`portfolio`, `cashly`, `mr-white`, `lafa-tools`, `docmost-custom`, `wiki`) utilizzano immagini ospitate su `ghcr.io` (alcune in repository privati). Inoltre, il container `watchtower` in [`compose/infrastructure.yml`](compose/infrastructure.yml) monta il file `~/.docker/config.json:/config.json`.

> [!CAUTION]
> **Esegui il `docker login` PRIMA del primo `docker compose up -d`!**  
> Se il file `~/.docker/config.json` non esiste sull'host quando avvii Watchtower, Docker lo creerà automaticamente come **directory vuota** anziché come file, causando il crash di Watchtower e impedendo i successivi login.

1. Genera su GitHub un **Personal Access Token (Classic)** con permesso `read:packages` (senza scadenza se usato per Watchtower).
2. Esegui il login dal terminale del Raspberry Pi (come utente `ingenitor`):
   ```bash
   docker login ghcr.io -u IL_TUO_USERNAME_GITHUB -p IL_TUO_GITHUB_PAT
   ```
3. Verifica che il file delle credenziali sia stato creato correttamente:
   ```bash
   cat ~/.docker/config.json
   ```

### 4.3 Creazione della Rete e dei Volumi Docker Esterni

Il file [`docker-compose.yml`](docker-compose.yml) e i moduli in [`compose/`](compose/) dichiarano la rete condivisa `common-network` e tre volumi principali con l'attributo `external: true`. Su una nuova installazione devono essere creati manualmente prima dell'avvio:

```bash
# 1. Crea la rete bridge condivisa tra tutti i container e cloudflared
docker network create common-network

# 2. Crea i volumi esterni per Cashly e Nextcloud (verranno salvati su RAID in /mnt/storage/docker/data/volumes)
docker volume create cashly-db_postgres_data
docker volume create nextcloud-db_data
docker volume create nextcloud_app_data
```

*(Nota: i volumi di Docmost `docmost_storage`, `docmost_db_data` e `docmost_redis_data` definiti in [`compose/docmost.yml`](compose/docmost.yml) non sono marcati `external: true` e verranno quindi creati in automatico da Docker Compose).*

### 4.4 Creazione Cartella Dati di Nextcloud sul RAID

In [`compose/nextcloud.yml`](compose/nextcloud.yml), i file caricati dagli utenti su Nextcloud non risiedono in un volume Docker ma in un bind mount diretto su `/mnt/storage/nextcloud/data`.  
Crea la directory e assegna la proprietà all'utente interno del container Apache (`www-data`, UID/GID `33`):

```bash
sudo mkdir -p /mnt/storage/nextcloud/data
sudo chown -R 33:33 /mnt/storage/nextcloud/data
sudo chmod -R 750 /mnt/storage/nextcloud/data
```

---

## Step 5 — Configurazione Variabili d'Ambiente (`.env`) e SMTP

Prima di avviare i container, crea il file `.env` a partire dal template fornito nel repository:

```bash
cd /mnt/storage/projects/server-raspberry-pi
cp .env.template .env
```

### 5.1 Configurazione Gmail SMTP per Cashly
👉 **Guida da seguire:** [**`guides/cashly_password_recovery_guide.md`**](guides/cashly_password_recovery_guide.md)

Segui la guida per abilitare la verifica in due passaggi sull'account Google, generare una **Password per le app** di 16 caratteri e compilare nel file `.env` le variabili:
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, `SMTP_FROM_NAME`.

### 5.2 Configurazione delle Restanti Variabili in `.env` *(Non documentate nelle altre guide)*

Apri il file `.env` (`nano .env`) e compila tutte le restanti sezioni presenti in [`.env.template`](.env.template):

| Sezione | Variabili in `.env` | Descrizione e Note di Configurazione |
| :--- | :--- | :--- |
| **Ambiente & Dominio** | `ASPNETCORE_ENVIRONMENT=Production`<br>`NODE_ENV=production`<br>`DOMAIN=robertoingenito.com` | Impostazioni globali di ambiente per i backend .NET / Node.js e dominio radice. |
| **Cashly DB** | `CASHLY_POSTGRES_USER=user`<br>`CASHLY_POSTGRES_PASSWORD=...`<br>`CASHLY_POSTGRES_DB=cashly_prod` | Credenziali del container PostgreSQL `cashly-database`. *(Nota: in [`compose/cashly.yml`](compose/cashly.yml) il DB espone anche la porta `5116:5432` sull'host per eventuali connessioni da client DB in LAN).* |
| **Nextcloud** | `NEXTCLOUD_DOMAIN=cloud.robertoingenito.com`<br>`NEXTCLOUD_CLI_URL=https://cloud.robertoingenito.com`<br>`NEXTCLOUD_DB_PASSWORD=...` | Dominio autorizzato (`TRUSTED_DOMAINS`), URL HTTPS per la CLI e password del database PostgreSQL `nextcloud-db`. |
| **LAFA Magazzino** | `LAFA_SUPABASE_URL=...`<br>`LAFA_SUPABASE_ANON_KEY=...`<br>`LAFA_FRONTEND_ORIGIN=https://lafa.robertoingenito.com`<br>`LAFA_LOGIN_PASSWORD=...` | Parametri per [`compose/lafa-tools.yml`](compose/lafa-tools.yml): URL e Anon Key del progetto Supabase esterno, origine frontend per il CORS e password di login all'applicazione. |
| **Docmost Custom** | `DOCMOST_APP_URL=https://docmost.robertoingenito.com`<br>`DOCMOST_APP_SECRET=...`<br>`DOCMOST_DB_USER=docmost_admin`<br>`DOCMOST_DB_NAME=docmost_db`<br>`DOCMOST_DB_PASSWORD=...` | Parametri per [`compose/docmost.yml`](compose/docmost.yml). **`DOCMOST_APP_SECRET` deve essere lunga almeno 32 caratteri** (puoi generarla con `openssl rand -hex 32`). |
| **Wiki (Digital Brain)** | `WIKI_PASSWORD=...` | Password di protezione per accedere al container della Wiki personale MkDocs ([`compose/wiki.yml`](compose/wiki.yml)). |
| **Cloudflare Tunnel** | `CLOUDFLARE_TUNNEL_TOKEN=...` | Token del tunnel generato su [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) (*Networks ➔ Tunnels ➔ Create a tunnel ➔ Cloudflared*). |
| **Cloudflare DDNS** | `CLOUDFLARE_ZONE=robertoingenito.com`<br>`CLOUDFLARE_API_TOKEN_DDNS=...` | Dominio e API Token (permesso *Edit zone DNS*) per aggiornare automaticamente l'IP pubblico sul record `ssh.robertoingenito.com` (dettagliato nello Step 7). |
| **Watchtower Webhook** | `WATCHTOWER_API_TOKEN=...` | Token segreto (generabile con `openssl rand -hex 32`) richiesto da `watchtower` per autorizzare gli aggiornamenti automatici innescati dalle GitHub Actions. |

---

## Step 6 — Avvio dello Stack Docker e Post-Configurazione Nextcloud

Una volta configurati rete, volumi, permessi e `.env`, puoi avviare l'intero stack applicativo e completare l'ottimizzazione di Nextcloud.

👉 **Guida da seguire:** [**`guides/docker_RAID_configuration.md`**](guides/docker_RAID_configuration.md) *(⚠️ **Sezioni "Start containers" e "NextCloud Configuration"**)*

### Cosa fare:
1. **Avvio dei container**:
   ```bash
   cd /mnt/storage/projects/server-raspberry-pi
   docker compose up -d
   ```
2. **Verifica stato dei servizi**:
   Controlla che tutti i container siano avviati correttamente (`Up` / `healthy`):
   ```bash
   docker compose ps
   ```
3. **Inizializzazione e Tuning di Nextcloud**:
   - Al primo avvio assoluto, attendi che `nextcloud-app` abbia completato l'inizializzazione iniziale (puoi monitorare i log con `docker compose logs -f nextcloud`).
   - Esegui i comandi `php occ` riportati nella sezione **NextCloud Configuration** di [`guides/docker_RAID_configuration.md`](guides/docker_RAID_configuration.md) per configurare:
     - Caching locale (`APCu`) e distribuito/file-locking su Redis (`nextcloud-redis`).
     - Generazione anteprime ad alta risoluzione (`2048x2048`, qualità JPEG `90`) e abilitazione dei provider per `PNG`, `JPEG`, `GIF`, `BMP`, `HEIC`, `MP3`, `TXT`, `MarkDown`, `PDF`.
     - Finestra per i job di manutenzione notturni (`maintenance_window_start = 3`) e regione telefonica predefinita (`IT`).
   - Riavvia Nextcloud con `docker compose restart nextcloud`.

---

## Step 7 — Cloudflare Tunnel, Routing, Watchtower CI/CD, SEO e SSH Remoto

Con i container attivi sulla rete locale del server, configura l'esposizione sicura su Internet tramite Cloudflare, il deploy continuo (CI/CD) con Watchtower, l'indicizzazione SEO e l'accesso SSH da remoto.

👉 **Guida da seguire:** [**`guides/cloudflare_guide.md`**](guides/cloudflare_guide.md)

### Ordine di esecuzione dentro la guida:
1. **Map of Subdomains and Docker Services (`cloudflare_guide.md`)**:
   - Nella dashboard Cloudflare Zero Trust (*Networks ➔ Tunnels ➔ Public Hostname*), aggiungi tutte le rotte elencate nella tabella puntandole ai rispettivi container sulla `common-network`.
   - ⚠️ **Rispetta l'ordine delle rotte**: le regole con un Path specifico (`/robots.txt`, `/sitemap.xml`, `/cashly-api*`, `/lafa-tools-api*`, `/mr-white-api*`, `/swagger*`) devono trovarsi **SOPRA** la regola con Path vuoto (`Empty`) dello stesso sottodominio.
   - ⚠️ **Abilita i WebSockets**: per `docmost.robertoingenito.com` e `mr-white.robertoingenito.com`, entra in *Additional application settings ➔ HTTP Settings* e attiva **Websockets**, altrimenti SignalR e la sincronizzazione in tempo reale non funzioneranno.
2. **Watchtower Webhook & GitHub Secrets (`cloudflare_guide.md`)**:
   - Il container `watchtower` ([`compose/infrastructure.yml`](compose/infrastructure.yml)) è configurato in modalità **event-driven** (`WATCHTOWER_HTTP_API_UPDATE=true`, `WATCHTOWER_HTTP_API_PERIODIC_POLLS=false`) e aggiorna **solo** i container dotati della label `com.centurylinklabs.watchtower.enable=true`.
   - Segui le istruzioni della guida per configurare il secret `WATCHTOWER_TOKEN` (con lo stesso valore di `WATCHTOWER_API_TOKEN` del `.env`) su ciascun repository GitHub (specialmente quelli privati, che su GitHub Free non ereditano i secret di organizzazione).
3. **SEO Management & Static Files Server (`cloudflare_guide.md`)**:
   - Il container `static-files` (basato su [`static-files/nginx.conf`](static-files/nginx.conf)) svolge due funzioni:
     1. Serve i file SEO dalla cartella [`seos/`](seos/): consente l'indicizzazione e fornisce `sitemap.xml` solo per `robertoingenito.com`, mentre restituisce `Disallow: /` (`seos/default/robots.txt`) per qualsiasi altro sottodominio.
     2. Serve le utility statiche su `calcolatori.robertoingenito.com` ([`/calcolatore-tasse/`](calcolatore-tasse/index.html) con redirect automatico dalla root `/` e [`/calcolatore-finanze/`](calcolatore-finanze/index.html)).
   - Registra la proprietà su Google Search Console e invia `https://robertoingenito.com/sitemap.xml`.
4. **Remote SSH Access (`cloudflare_guide.md`)**:
   - Crea l'API Token Cloudflare per il DDNS, inseriscilo in `.env` (`CLOUDFLARE_API_TOKEN_DDNS`) e riavvia `cloudflare-ddns` (`docker compose up -d cloudflare-ddns`).
   - Crea il record DNS di tipo `A` per `ssh.robertoingenito.com` lasciando il **Proxy disattivato (Nuvoletta Grigia / DNS Only)**.
   - Configura il Port Forwarding sul router di casa mappando una porta esterna casuale alta (es. `45222`) verso la porta `22` dell'IP locale del Raspberry Pi (`192.168.1.100`).

---

## Step 8 — Backup Automatici dei Database e Persistenza Dati

Con tutti i servizi operativi in produzione, configura la strategia di salvataggio automatico dei database PostgreSQL sul volume RAID 1.

👉 **Guida da seguire:** [**`guides/backup_and_restore_postgres.md`**](guides/backup_and_restore_postgres.md)

### Cosa fare:
1. Rendi eseguibile lo script [`scripts/backup-databases.sh`](scripts/backup-databases.sh) ed esegui un test manuale per verificare che i dump compressi (`.sql.gz`) di **Cashly**, **Nextcloud** e **Docmost** vengano creati in `/mnt/storage/backups/databases/`.
2. Configura il **Cron Job** dell'utente `ingenitor` (`crontab -e`) per eseguire il backup automatico ogni notte alle `03:00` (con pulizia automatica dei backup più vecchi di 14 giorni).

### 💡 Riepilogo Dati Persistenti da Includere in un Piano di Disaster Recovery *(Non documentato altrove)*
Oltre ai dump SQL generati dallo script in `/mnt/storage/backups/databases/`, tieni presente dove risiedono tutti gli altri dati di stato del server nel caso volessi sincronizzarli su un disco esterno o cloud off-site:
- **File caricati su Nextcloud**: `/mnt/storage/nextcloud/data` (e configurazione app nel volume Docker `nextcloud_app_data`).
- **Allegati e immagini caricati su Docmost**: volume Docker `docmost_storage` (situato in `/mnt/storage/docker/data/volumes/server-raspberry-pi_docmost_storage/_data`).
- **Configurazione segreta dello stack**: il file `/mnt/storage/projects/server-raspberry-pi/.env` (non tracciato su Git per sicurezza).
- **Configurazione RAID e Mount di sistema**: `/etc/mdadm/mdadm.conf` e `/etc/fstab` (come indicato in [`guides/RAID_configuration.md`](guides/RAID_configuration.md), salvabili in `/mnt/storage/backups/`).

---

## Step 9 — Manutenzione Periodica e Ottimizzazione Spazio (Server & WSL2)

Nel tempo, gli aggiornamenti frequenti delle immagini tramite Watchtower e le build Docker possono accumulare cache e layer inutilizzati.

👉 **Guida da seguire:** [**`guides/Docker-WSL2-Optimization-Guide.md`**](guides/Docker-WSL2-Optimization-Guide.md)

### Cosa fare:
- **Sul Server Raspberry Pi (e in locale)**:
  - Usa le sezioni **1 (Space Analysis)** e **2 (Cleanup)** della guida (`docker system df`, `docker builder prune -a`, `docker image prune -a`, `docker volume prune`) per monitorare e liberare spazio su disco in modo sicuro. *(Nota: Watchtower è già configurato con `WATCHTOWER_CLEANUP=true` per rimuovere automaticamente le vecchie immagini ad ogni deploy).*
- **Sulla macchina Windows di sviluppo (WSL2)**:
  - Usa la sezione **3 (WSL2 disk compaction)** e la procedura di **Troubleshooting (`fstrim` + `diskpart`)** per compattare il file virtuale `docker_data.vhdx` quando Docker Desktop su Windows non rilascia lo spazio su disco dopo il prune.
