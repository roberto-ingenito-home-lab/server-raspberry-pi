# 🚀 Docker Projects Hub

Collezione di applicazioni e servizi self-hosted, orchestrati tramite Docker su un server domestico.

## 🏗️ Architettura

L'infrastruttura utilizza Cloudflare Tunnel per il routing sicuro, la gestione del certificato SSL e la sicurezza, eliminando la necessità di porte pubbliche aperte.

| Componente          | Tecnologia                                  |
| ------------------- | ------------------------------------------- |
| Tunnel & DNS        | Cloudflare Tunnel (`cloudflared`)           |
| SSL                 | Gestito da Cloudflare                       |
| Database principale | PostgreSQL                                  |
| Database Obsidian   | CouchDB                                     |
| Cache               | Redis (Nextcloud)                           |

---

## 📱 Applicazioni

### 💼 Portfolio

Sito web di presentazione / portfolio personale.

- **Frontend**: React (TypeScript) + Vite → `/`

### 💰 Cashly

Gestione finanze personali.

- **Backend**: .NET Core Web API → `/cashly-api/`
- **Frontend**: Angular → `/cashly/`
- **Database**: PostgreSQL

### 🎮 Mr. White Game

Gioco interattivo con ruoli e parole segrete.

- **Backend**: .NET Core + SignalR (WebSocket) → `/mr-white-api/`
- **Frontend**: Next.js → `/mr-white/`

### 📂 Nextcloud

Cloud storage personale.

- **Stack**: PHP/Apache, PostgreSQL, Redis
- **Storage**: Unità RAID esterna (`/mnt/storage/nextcloud/data`)
- **Path**: `/cloud/`

### 📊 Fortil Excel Timesheet

Tool per la gestione dei fogli ore (Vite/React) → `/timesheet/`

### 🔄 CouchDB

Sincronizzazione Obsidian LiveSync → `/couchdb-obsidian/`

### 🧮 Calcolatori Statici

Utility HTML/JS servite da nginx interno:

- `/calcolatore-finanze/`
- `/calcolatore-tasse/`

### 🗄️ pgAdmin

Interfaccia web per PostgreSQL → porta `5050` (accesso diretto)

---

## ⚙️ Setup

### 1. Prerequisiti

- Docker e Docker Compose installati
- Dominio configurato su Cloudflare con un Tunnel attivo
- Variabile `CLOUDFLARE_TUNNEL_TOKEN` configurata nel file `.env`

### 2. Configurazione ambiente

```bash
cp .env.template .env
nano .env
```

### 3. Avvio

**Produzione:**

```bash
docker compose up -d
```

Il container `cloudflared` si connetterà automaticamente a Cloudflare, esponendo i servizi configurati in modo sicuro.

**Sviluppo:**

```bash
docker compose --env-file .env.dev up --build -d
```

---


## 🔀 Routing

La gestione delle rotte e dei domini non avviene più tramite reverse proxy locale (Traefik), ma è delegata interamente a Cloudflare Tunnel tramite la console web di Cloudflare Zero Trust.

Per la mappa completa dei sottodomini e dei relativi servizi Docker interni configurati, consulta il file di documentazione [cloudflare_guide.md](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/cloudflare_guide.md).

---

## 🛠️ Comandi utili

```bash
# Log di un servizio
docker compose logs -f [service-name]

# Stato dei container
docker ps

# Riavviare un singolo servizio
docker compose restart [service-name]

# Aggiornare un servizio senza downtime degli altri
docker compose up -d --build [service-name]
```

---

## 📄 Documentazione correlata

- [🛠️ Infrastructure & Host Setup](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/INFRASTRUCTURE.md)
- [🐳 Configurazione Docker per il RAID](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/configurazione_docker.md)
- [☁️ Configurazione Cloudflare](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/cloudflare_guide.md)
- [💾 Backup & Restore Postgres](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/backup_and_restore_postgres.md)
- [🗄️ Configurazione RAID](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/configurazione_raid.md)
- [📝 Obsidian Sync](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/configurazione_obsidian_sync.md)
- [🧹 Guida Pulizia e Ottimizzazione WSL2](file:///C:/Users/roberto/Documents/GitHub/server-raspberry-pi/Docker-WSL2-Optimization-Guide.md)
