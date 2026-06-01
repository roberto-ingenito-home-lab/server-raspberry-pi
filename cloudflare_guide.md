# 🚀 Piano di Migrazione: Cloudflare Tunnel & Polyrepo

Questo documento contiene la guida passo-passo per completare la transizione del tuo server domestico su **Cloudflare Tunnel** con architettura **Polyrepo**.

---

## 🌐 1. Configurazione su Cloudflare Zero Trust Dashboard

Poiché utilizzi il tunnel in modalità remota (gestito tramite `--token TOKEN`), la configurazione del routing e dei sottodomini avviene direttamente dal pannello web di Cloudflare.

### Passi da seguire:

1. Accedi a [Cloudflare Zero Trust](https://one.dash.cloudflare.com/).
2. Vai su **Networks** ➔ **Tunnels**.
3. Seleziona il tuo tunnel e clicca su **Configure**.
4. Vai nella tab **Public Hostname** e aggiungi le rotte per i tuoi servizi.

### 📋 Mappa dei Sottodomini e Servizi Docker

Configura le seguenti regole di hostname per far corrispondere i sottodomini ai relativi container interni nella rete Docker `common-network`:

| Public Hostname (Sottodominio)    | Path (Opzionale) | Service Type | URL (Nome Container)                 | Note                      |
| :-------------------------------- | :--------------- | :----------- | :----------------------------------- | :------------------------ |
| `cashly.robertoingenito.com`      | _Vuoto_          | HTTP         | `http://cashly-front-end:80`         | Frontend di Cashly        |
| `cashly.robertoingenito.com`      | `/cashly-api*`   | HTTP         | `http://cashly-back-end:80`          | Backend API di Cashly     |
| `cashly.robertoingenito.com`      | `/swagger*`      | HTTP         | `http://cashly-back-end:80`          | Documentazione API        |
| `mr-white.robertoingenito.com`    | _Vuoto_          | HTTP         | `http://mr-white-front-end:3000`     | Frontend di Mr. White     |
| `mr-white.robertoingenito.com`    | `/mr-white-api*` | HTTP         | `http://mr-white-back-end:80`        | Backend WebSockets        |
| `cloud.robertoingenito.com`       | _Vuoto_          | HTTP         | `http://nextcloud-app:80`            | Nextcloud Storage         |
| `obsidian.robertoingenito.com`    | _Vuoto_          | HTTP         | `http://couchdb-obsidian:5984`       | Sincronizzazione Obsidian |
| `timesheet.robertoingenito.com`   | _Vuoto_          | HTTP         | `http://fortil-excel-timesheet:3000` | Timesheet utility         |
| `calcolatori.robertoingenito.com` | _Vuoto_          | HTTP         | `http://static-files:80`             | Pagine utility statiche   |

> [!NOTE]
> Per le regole con path (es. `/cashly-api*`), Cloudflare inoltrerà automaticamente il path al container. Questo mantiene l'API ed il frontend sullo stesso sottodominio, eliminando problemi di CORS.

---

## 📦 2. GitHub Actions per i Repository Applicativi (Fase 2)

Quando sposterai le applicazioni (es. `cashly`, `mr-white`) nei loro repository individuali su GitHub, dovrai compilare le immagini Docker e caricarle in un registry come **GHCR (GitHub Container Registry)**.

Dal momento che il tuo server gira su un **Raspberry Pi**, le immagini devono essere compilate per l'architettura **ARM64**. GitHub usa macchine host x86_64 (AMD64), per cui è necessario usare **QEMU** per emulare la build ARM64, altrimenti otterresti un errore del tipo `exec format error`.

Crea questo file in ogni repository applicativo sotto `.github/workflows/build-and-push.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]

env:
  REGISTRY: ghcr.io
  # Sostituisci con il tuo username GitHub in minuscolo
  IMAGE_NAME: ${{ github.repository_owner }}/cashly-frontend

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      # Configura QEMU per supportare build multi-architettura (fondamentale per Raspberry Pi)
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Login su GitHub Container Registry
      - name: Log in to the Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Estrae tag e metadata per Docker
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha,prefix=

      # Builda e pusha l'immagine per AMD64 (PC) e ARM64 (Raspberry Pi)
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ id.meta.outputs.tags }}
          labels: ${{ id.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 🏠 3. Come diventerà il `docker-compose.yml` del Server

Una volta spostate le applicazioni nei rispettivi repository, il file `docker-compose.yml` nel tuo repository principale `server` userà le immagini caricate su GHCR.

Esempio di come referenziare le nuove immagini:

```yaml
cashly-front-end:
  image: ghcr.io/robertoingenito/cashly-front-end:main
  container_name: cashly-front-end
  expose:
    - "80"
  networks:
    - common-network
  restart: always
  depends_on:
    - cashly-back-end

cashly-back-end:
  image: ghcr.io/robertoingenito/cashly-back-end:main
  container_name: cashly-back-end
  expose:
    - "80"
  # ... resto delle variabili d'ambiente e db ...
```

> [!TIP]
> Se i tuoi repository saranno privati su GitHub (e quindi le immagini GHCR richiederanno autenticazione per essere scaricate), ricordati di:
>
> 1. Fare il login sul tuo server tramite shell con: `docker login ghcr.io -u IL_TUO_USERNAME -p IL_TUO_TOKEN_GITHUB`
> 2. Decommentare la riga del volume nel servizio `watchtower` per montare la configurazione di Docker del server:
>    ```yaml
>    volumes:
>      - /var/run/docker.sock:/var/run/docker.sock
>      - ~/.docker/config.json:/config.json
>    ```
>    In questo modo Watchtower userà automaticamente le tue credenziali per aggiornare le app private!
