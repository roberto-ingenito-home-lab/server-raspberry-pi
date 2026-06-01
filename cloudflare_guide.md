# Configurazione su Cloudflare Zero Trust Dashboard

Poiché utilizzi il tunnel in modalità remota (gestito tramite `--token TOKEN`), la configurazione del routing e dei sottodomini avviene direttamente dal pannello web di Cloudflare.

## Passi da seguire:

1. Accedi a [Cloudflare Zero Trust](https://one.dash.cloudflare.com/).
2. Vai su **Networks** ➔ **Tunnels**.
3. Seleziona il tuo tunnel e clicca su **Configure**.
4. Vai nella tab **Public Hostname** e aggiungi le rotte per i tuoi servizi.

## Mappa dei Sottodomini e Servizi Docker

Configura le seguenti regole di hostname per far corrispondere i sottodomini ai relativi container interni nella rete Docker `common-network`:

| Public Hostname (Sottodominio)    | Path (Opzionale)       | Service Type | URL (Nome Container)                  | Note                       |
| :-------------------------------- | :--------------------- | :----------- | :------------------------------------ | :------------------------- |
| `robertoingenito.com`             | _Vuoto_                | HTTP         | `http://portfolio-app:80`             | Portfolio Principale       |
| `cashly.robertoingenito.com`      | `/cashly-api*`         | HTTP         | `http://cashly-back-end:80`           | Backend API di Cashly      |
| `cashly.robertoingenito.com`      | `/swagger*`            | HTTP         | `http://cashly-back-end:80`           | Documentazione API         |
| `cashly.robertoingenito.com`      | _Vuoto_                | HTTP         | `http://cashly-front-end:80`          | Frontend di Cashly         |
| `mr-white.robertoingenito.com`    | `/mr-white-api*`       | HTTP         | `http://mr-white-back-end:80`         | Backend WebSockets         |
| `mr-white.robertoingenito.com`    | _Vuoto_                | HTTP         | `http://mr-white-front-end:3000`      | Frontend di Mr. White      |
| `cloud.robertoingenito.com`       | _Vuoto_                | HTTP         | `http://nextcloud-app:80`             | Nextcloud Storage          |
| `obsidian.robertoingenito.com`    | _Vuoto_                | HTTP         | `http://couchdb-obsidian:5984`        | Sincronizzazione Obsidian  |
| `timesheet.robertoingenito.com`   | _Vuoto_                | HTTP         | `http://fortil-excel-timesheet:3000`  | Timesheet utility          |
| `calcolatori.robertoingenito.com` | _Vuoto_                | HTTP         | `http://static-files:80`              | Pagine utility statiche    |
| `lafa.robertoingenito.com`        | `/lafa-magazzino-api*` | HTTP         | `http://lafa-magazzino-back-end:8080` | Backend API di LAFA        |
| `lafa.robertoingenito.com`        | `/swagger*`            | HTTP         | `http://lafa-magazzino-back-end:8080` | Documentazione API LAFA    |
| `lafa.robertoingenito.com`        | _Vuoto_                | HTTP         | `http://lafa-magazzino-front-end:80`  | Frontend di LAFA Magazzino |

> [!IMPORTANT]
> **ORDINE DELLE REGISTRAZIONI (ROTTE) SU CLOUDFLARE:**
> L'ordine con cui le rotte sono posizionate in Cloudflare è fondamentale. Cloudflare valuta le regole dall'alto verso il basso:
>
> 1. Le rotte con un percorso specifico (come `/cashly-api*` o `/swagger*`) **devono essere posizionate SOPRA** alla rotta generica con percorso vuoto (`_Vuoto_`).
> 2. Se la rotta con percorso `_Vuoto_` (che punta al frontend) si trova sopra le altre, Cloudflare catturerà tutto il traffico indirizzato a quel sottodominio e lo invierà al frontend, ignorando le regole successive per le API o Swagger.

> [!NOTE]
> Per le regole con path (es. `/cashly-api*`), Cloudflare inoltrerà automaticamente il path al container. Questo mantiene l'API ed il frontend sullo stesso sottodominio, eliminando problemi di CORS.

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
