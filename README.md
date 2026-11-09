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

### 🧠 Wiki (Digital Brain)

Knowledge base e documentazione personale (SAP Business One, integrazioni, architettura e note tecniche).

- **Stack**: MkDocs Material (Python / Pygments), Nginx
- **Repo**: [wiki](https://github.com/roberto-ingenito-home-lab/wiki) (Privata)

### 📂 Nextcloud

Cloud storage personale.

- **Stack**: PHP/Apache, PostgreSQL, Redis
- **Storage**: Unità RAID esterna (`/mnt/storage/nextcloud/data`)
- **Path**: `/cloud/`

### 🧮 Calcolatori Statici

Utility HTML/JS servite da nginx interno:

- `/calcolatore-finanze/`
- `/calcolatore-tasse/`

---

## ⚙️ Setup

> 🗺️ **Configurazione da zero del server?** Segui la [**Guida Principale di Setup (Step-by-Step)**](server_setup_guide.md), che ti accompagna in ordine cronologico attraverso tutte le guide e i passaggi preparatori.

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
│   └── wiki.yml
├── calcolatore-finanze/        # Codice sorgente calcolatore finanze
├── calcolatore-tasse/          # Codice sorgente calcolatore tasse
├── guides/                     # Guide specifiche di configurazione e manutenzione
├── scripts/                    # Script di automazione e backup database
├── seos/                       # File SEO (robots.txt, sitemap.xml)
├── static-files/               # File statici serviti da Nginx
├── .env.template               # Template variabili d'ambiente
└── server_setup_guide.md       # Guida principale di setup passo-passo
```

Il `docker-compose.yml` principale utilizza la direttiva `include` per importare i compose modulari dalla cartella `compose/`, mantenendo ogni servizio isolato e facilmente gestibile.

---

## 🔀 Routing

La gestione delle rotte e dei domini è delegata interamente a Cloudflare Tunnel tramite la console web di Cloudflare Zero Trust.

Per la mappa completa dei sottodomini e dei relativi servizi Docker interni configurati, consulta il file di documentazione [cloudflare_guide.md](guides/cloudflare_guide.md).

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

- **[🗺️ Guida Principale di Setup del Server (Step-by-Step)](server_setup_guide.md)**
- [🗄️ Configurazione OS & RAID 1 NVMe](guides/RAID_configuration.md)
- [🏗️ Infrastruttura & Rete Host](guides/raspberry_pi_infrastructure.md)
- [🛡️ Sicurezza SSH con Fail2ban](guides/fail2ban_guide.md)
- [🐳 Configurazione Docker sul RAID & Nextcloud](guides/docker_RAID_configuration.md)
- [🔑 Configurazione SMTP & Recupero Password Cashly](guides/cashly_password_recovery_guide.md)
- [☁️ Configurazione Cloudflare, Watchtower, SEO & SSH Remoto](guides/cloudflare_guide.md)
- [💾 Backup & Restore Database PostgreSQL](guides/backup_and_restore_postgres.md)
- [🧹 Guida Pulizia e Ottimizzazione Spazio Docker / WSL2](guides/Docker-WSL2-Optimization-Guide.md)
