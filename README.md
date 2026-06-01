# 🚀 Docker Projects Hub

Collezione di applicazioni e servizi self-hosted, orchestrati tramite Docker su un server domestico.

## 🏗️ Architettura

L'infrastruttura usa un reverse proxy centralizzato per routing, SSL e sicurezza.

| Componente          | Tecnologia                                  |
| ------------------- | ------------------------------------------- |
| Reverse Proxy       | Traefik v3                                  |
| SSL                 | Let's Encrypt via ACME (gestito da Traefik) |
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
- Dominio configurato (es. DDNS su NO-IP)
- Porte 80 e 443 aperte sul router

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

Traefik ottiene automaticamente i certificati Let's Encrypt al primo avvio.

**Sviluppo:**

```bash
docker compose --env-file .env.dev up --build -d
```

Traefik genera un certificato self-signed automatico. Il browser mostrerà un avviso SSL — normale in locale.

---


## 🔀 Routing

| Path                    | Servizio               | Note                                  |
| ----------------------- | ---------------------- | ------------------------------------- |
| `/`                     | portfolio              |                                       |
| `/cashly-api/`          | cashly-back-end        | Rate limit: 30 req/min                |
| `/swagger`              | cashly-back-end        | Rate limit: 10 req/min                |
| `/cashly/`              | cashly-front-end       |                                       |
| `/timesheet/`           | fortil-excel-timesheet | Strip prefix                          |
| `/cloud/`               | nextcloud              | Strip prefix                          |
| `/mr-white-api/`        | mr-white-back-end      | WebSocket (SignalR)                   |
| `/mr-white/`            | mr-white-front-end     |                                       |
| `/couchdb-obsidian/`    | couchdb-obsidian       | Strip prefix, rate limit: 120 req/min |
| `/calcolatore-finanze/` | static-files           | SPA statica                           |
| `/calcolatore-tasse/`   | static-files           | SPA statica                           |

Dashboard Traefik disponibile su `http://localhost:8080` (solo accesso locale).

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

- [🛠️ Infrastructure & Host Setup](INFRASTRUCTURE.md)
- [🐳 Configurazione Docker per il RAID](configurazione_docker.md)
- [💾 Backup & Restore Postgres](backup_and_restore_postgres.md)
- [🗄️ Configurazione RAID](configurazione_raid.md)
- [📝 Obsidian Sync](configurazione_obsidian_sync.md)
- [🧹 Guida Pulizia e Ottimizzazione WSL2](Docker-WSL2-Optimization-Guide.md)
