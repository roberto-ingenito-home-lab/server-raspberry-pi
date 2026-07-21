# 🚀 Docker Projects Hub

Collezione di applicazioni e servizi self-hosted, orchestrati tramite Docker su un server domestico.

## 🏗️ Architettura

L'infrastruttura utilizza Cloudflare Tunnel per il routing sicuro, la gestione del certificato SSL e la sicurezza, eliminando la necessità di porte pubbliche aperte.

| Componente          | Tecnologia                                  |
| ------------------- | ------------------------------------------- |
| Tunnel & DNS        | Cloudflare Tunnel (`cloudflared`)           |
| SSL                 | Gestito da Cloudflare                       |
| Database principale | PostgreSQL                                  |
| Cache               | Redis (Nextcloud, Docmost)                  |

---

## 📱 Applicazioni

### 💼 Portfolio

Sito web di presentazione / portfolio personale.

- **Frontend**: React (TypeScript) + Vite → `/`
- **Repo**: [portfolio](https://github.com/roberto-ingenito-home-lab/portfolio)

### 💰 Cashly

Gestione finanze personali.

- **Backend**: .NET Core Web API → `/cashly-api/`
- **Frontend**: Angular → `/cashly/`
- **Database**: PostgreSQL
- **Repo**: [cashly-backend](https://github.com/roberto-ingenito-home-lab/cashly-backend) · [cashly-frontend](https://github.com/roberto-ingenito-home-lab/cashly-frontend)

### 🎮 Mr. White Game

Gioco interattivo con ruoli e parole segrete.

- **Backend**: .NET Core + SignalR (WebSocket) → `/mr-white-api/`
- **Frontend**: Next.js → `/mr-white/`
- **Repo**: [mr-white-backend](https://github.com/roberto-ingenito-home-lab/mr-white-backend) · [mr-white-frontend](https://github.com/roberto-ingenito-home-lab/mr-white-frontend)

### 📦 LAFA Tools

Sistema di gestione magazzino con aggiornamenti in tempo reale, scansione barcode/QR e UI mobile-first.

- **Backend**: ASP.NET Core + SignalR → `/lafa-tools-api/`
- **Frontend**: Angular → `/lafa/`
- **Database**: Supabase (PostgreSQL)
- **Repo**: [LAFA-tools-backend](https://github.com/roberto-ingenito-home-lab/LAFA-tools-backend) · [LAFA-tools-frontend](https://github.com/roberto-ingenito-home-lab/LAFA-tools-frontend)

### 📝 Docmost

Wiki e documentazione collaborativa (fork personalizzato con modifiche custom).

- **Stack**: Node.js/NestJS, React, PostgreSQL, Redis
- **Repo**: [docmost](https://github.com/roberto-ingenito-home-lab/docmost)

### 📂 Nextcloud

Cloud storage personale.

- **Stack**: PHP/Apache, PostgreSQL, Redis
- **Storage**: Unità RAID esterna (`/mnt/storage/nextcloud/data`)
- **Path**: `/cloud/`

### 📊 Fortil Excel Timesheet

Tool per la gestione dei fogli ore (Vite/React) → `/timesheet/`

- **Repo**: [fortil-excel-timesheet](https://github.com/roberto-ingenito-home-lab/fortil-excel-timesheet)

### 🧮 Calcolatori Statici

Utility HTML/JS servite da nginx interno:

- `/calcolatore-finanze/`
- `/calcolatore-tasse/`

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

## 📁 Struttura del Progetto

```
server-raspberry-pi/
├── docker-compose.yml          # Compose principale (include i file dalla cartella compose/)
├── compose/                    # File compose modulari per ogni servizio
│   ├── infrastructure.yml      # Cloudflare, Watchtower, Static Files
│   ├── cashly.yml
│   ├── mr-white.yml
│   ├── lafa-tools.yml
│   ├── docmost.yml
│   ├── nextcloud.yml
│   ├── portfolio.yml
│   └── fortil-excel-timesheet.yml
├── calcolatore-finanze/        # Codice sorgente calcolatore finanze
├── calcolatore-tasse/          # Codice sorgente calcolatore tasse
├── seos/                       # File SEO (robots.txt, sitemap.xml)
├── static-files/               # File statici serviti da Nginx
├── .env.template               # Template variabili d'ambiente
└── *.md                        # Guide di configurazione
```

Il `docker-compose.yml` principale utilizza la direttiva `include` per importare i compose modulari dalla cartella `compose/`, mantenendo ogni servizio isolato e facilmente gestibile.

---

## 🔀 Routing

La gestione delle rotte e dei domini è delegata interamente a Cloudflare Tunnel tramite la console web di Cloudflare Zero Trust.

Per la mappa completa dei sottodomini e dei relativi servizi Docker interni configurati, consulta il file di documentazione [cloudflare_guide.md](cloudflare_guide.md).

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

- [🏗️ Infrastruttura & Setup Host](raspberry_pi_infrastructure.md)
- [🐳 Configurazione Docker per il RAID](docker_RAID_configuration.md)
- [☁️ Configurazione Cloudflare](cloudflare_guide.md)
- [💾 Backup & Restore Postgres](backup_and_restore_postgres.md)
- [🗄️ Configurazione RAID](RAID_configuration.md)
- [🔑 Recupero Password Cashly](cashly_password_recovery_guide.md)
- [🧹 Guida Pulizia e Ottimizzazione WSL2](Docker-WSL2-Optimization-Guide.md)
