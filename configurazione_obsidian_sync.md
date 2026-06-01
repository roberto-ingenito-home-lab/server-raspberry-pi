# Configurazione Obsidian Self-hosted LiveSync

Questa guida spiega come configurare l'estensione **Self-hosted LiveSync** in Obsidian per sincronizzare le tue note utilizzando l'istanza CouchDB configurata su Docker, accessibile tramite HTTPS.

## Configurazione CouchDB (Inizializzazione)

Per far funzionare correttamente il plugin, è necessario creare i database di sistema su CouchDB. Sostituisci `<USERNAME>` e `<PASSWORD>` con le tue credenziali.

```bash
curl -X PUT http://192.168.1.20:5984/_users -u "<USERNAME>:<PASSWORD>"
curl -X PUT http://192.168.1.20:5984/_replicator -u "<USERNAME>:<PASSWORD>"
curl -X PUT http://192.168.1.20:5984/_global_changes -u "<USERNAME>:<PASSWORD>"
```

Una volta eseguiti i comandi, riavvia i container:

```bash
docker compose restart couchdb-obsidian
```

## Configurazione in Obsidian

1. Installa il plugin **Self-hosted LiveSync** in Obsidian.
2. Apri le impostazioni del plugin.
3. Nella sezione **Remote Configuration**, imposta i seguenti parametri:
   - **SERVER URI**: `https://roberto-ingenito.ddns.net/couchdb-obsidian/`
   - **Username**: Il tuo username CouchDB.
   - **Password**: La tua password CouchDB.
   - **Database name**: Inserisci un nome **coerente con il nome del tuo Vault** (es. se il vault si chiama `NotePersonali`, usa `note_personali`). CouchDB richiede nomi in minuscolo.
4. **Importante**: Nella sezione **Sync Settings**, imposta il **SyncMode** a `LiveSync`.
