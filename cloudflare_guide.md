# Configurazione su Cloudflare Zero Trust Dashboard

Poiché utilizzi il tunnel in modalità remota (gestito tramite `--token TOKEN`), la configurazione del routing e dei sottodomini avviene direttamente dal pannello web di Cloudflare.

## Passi da seguire:

1. Accedi a [Cloudflare Zero Trust](https://one.dash.cloudflare.com/).
2. Vai su **Networks** ➔ **Tunnels**.
3. Seleziona il tuo tunnel e clicca su **Configure**.
4. Vai nella tab **Public Hostname** e aggiungi le rotte per i tuoi servizi.

## Mappa dei Sottodomini e Servizi Docker

Configura le seguenti regole di hostname per far corrispondere i sottodomini ai relativi container interni nella rete Docker `common-network`:

| Public Hostname (Sottodominio)    | Path (Opzionale)   | Service Type | URL (Nome Container)                 | Note                          |
| :-------------------------------- | :----------------- | :----------- | :----------------------------------- | :---------------------------- |
| `robertoingenito.com`             | `/robots.txt`      | HTTP         | `http://static-files:80`             | Gestione robots.txt (SEO)     |
| `robertoingenito.com`             | `/sitemap.xml`     | HTTP         | `http://static-files:80`             | Gestione sitemap.xml (SEO)    |
| `robertoingenito.com`             | _Vuoto_            | HTTP         | `http://portfolio-app:80`            | Portfolio Principale          |
| `cashly.robertoingenito.com`      | `/cashly-api*`     | HTTP         | `http://cashly-back-end:80`          | Backend API di Cashly         |
| `cashly.robertoingenito.com`      | `/swagger*`        | HTTP         | `http://cashly-back-end:80`          | Documentazione API            |
| `cashly.robertoingenito.com`      | _Vuoto_            | HTTP         | `http://cashly-front-end:80`         | Frontend di Cashly            |
| `mr-white.robertoingenito.com`    | `/mr-white-api*`   | HTTP         | `http://mr-white-back-end:80`        | Backend WebSockets            |
| `mr-white.robertoingenito.com`    | _Vuoto_            | HTTP         | `http://mr-white-front-end:3000`     | Frontend di Mr. White         |
| `cloud.robertoingenito.com`       | _Vuoto_            | HTTP         | `http://nextcloud-app:80`            | Nextcloud Storage             |
| `obsidian.robertoingenito.com`    | _Vuoto_            | HTTP         | `http://couchdb-obsidian:5984`       | Sincronizzazione Obsidian     |
| `timesheet.robertoingenito.com`   | _Vuoto_            | HTTP         | `http://fortil-excel-timesheet:3000` | Timesheet utility             |
| `calcolatori.robertoingenito.com` | _Vuoto_            | HTTP         | `http://static-files:80`             | Pagine utility statiche       |
| `lafa.robertoingenito.com`        | `/lafa-tools-api*` | HTTP         | `http://lafa-tools-back-end:8080`    | Backend API di LAFA Tools     |
| `lafa.robertoingenito.com`        | `/swagger*`        | HTTP         | `http://lafa-tools-back-end:8080`    | Documentazione API LAFA       |
| `lafa.robertoingenito.com`        | _Vuoto_            | HTTP         | `http://lafa-tools-front-end:80`     | Frontend di LAFA Tools        |
| `affine.robertoingenito.com`      | _Vuoto_            | HTTP         | `http://affine-server:3010`          | Workspace AFFiNE (Notion alt) |

> [!IMPORTANT]
> **ORDINE DELLE REGISTRAZIONI (ROTTE) SU CLOUDFLARE:**
> L'ordine con cui le rotte sono posizionate in Cloudflare è fondamentale. Cloudflare valuta le regole dall'alto verso il basso:
>
> 1. Le rotte con un percorso specifico (come `/robots.txt`, `/sitemap.xml`, `/cashly-api*` o `/swagger*`) **devono essere posizionate SOPRA** alla rotta generica con percorso vuoto (`Vuoto`).
> 2. Se la rotta con percorso `Vuoto` (che punta al frontend) si trova sopra le altre, Cloudflare catturerà tutto il traffico indirizzato a quel sottodominio e lo invierà al frontend, ignorando le regole successive per le API, Swagger o i file SEO.

> [!NOTE]
> Per le regole con path (es. `/cashly-api*`), Cloudflare inoltrerà automaticamente il path al container. Questo mantiene l'API ed il frontend sullo stesso sottodominio, eliminando problemi di CORS.

> [!IMPORTANT]
> **ABILITAZIONE WEBSOCKET PER INSTRADAMENTO IN TEMPO REALE:**
> Servizi come **AFFiNE** (tramite protocollo di sincronizzazione Yjs) e **Mr. White** (tramite SignalR) dipendono strettamente da connessioni WebSocket persistenti.
> Per ciascuno di questi sottodomini, nella console web di Cloudflare Zero Trust:
>
> 1. Entra in modifica della rotta (`Public Hostname`).
> 2. Espandi la sezione **Additional application settings**.
> 3. Clicca su **HTTP Settings**.
> 4. Attiva lo switch **Websockets** (impostalo su _Enabled_). Se non viene abilitato, l'interfaccia dell'applicazione si avvierà ma non sarà in grado di stabilire la connessione in tempo reale e non sincronizzerà le note.

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

---

## 📈 Gestione SEO e Google Search Console

Abbiamo configurato il server Nginx in modalità centralizzata per servire i file di indicizzazione SEO esclusivamente per il portfolio principale `robertoingenito.com` ed escludere tutti gli altri sottodomini.

### Struttura dei file sul server

I file SEO si trovano nella cartella `./seos/` del repository:

- **`seos/default/robots.txt`**: File generico che impedisce l'indicizzazione (`Disallow: /`). Viene servito a tutti i sottodomini non configurati espressamente (es. `calcolatori.`, `cashly.`, `cloud.`).
- **`seos/robertoingenito.com/robots.txt` & `sitemap.xml`**: Permettono l'indicizzazione ed indicano a Googlebot la sitemap del portfolio principale.

### Procedura di attivazione:

1. **Rotte Cloudflare**: Assicurati di configurare le rotte per `/robots.txt` e `/sitemap.xml` di `robertoingenito.com` indirizzandole a `http://static-files:80` (inserendole **in alto** rispetto a quella generica del portfolio).
2. **Verifica Dominio su GSC**: Aggiungi la proprietà **Dominio** per `robertoingenito.com` in Google Search Console
3. **Invia la Sitemap**: Nel pannello Search Console di `robertoingenito.com`, vai su **Sitemaps** ed invia l'URL `https://robertoingenito.com/sitemap.xml`.
