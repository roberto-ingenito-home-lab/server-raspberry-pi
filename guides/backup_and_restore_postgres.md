# PostgreSQL Backup and Restore

Questa guida documenta la strategia di backup automatico e le procedure di ripristino per i database PostgreSQL dell'infrastruttura (**Cashly**, **Nextcloud**, **Docmost**).

---

## ⏰ Backup Automatico Giornaliero (Cron Job)

Nella cartella `scripts/` è presente lo script [`backup-databases.sh`](../scripts/backup-databases.sh) che:
- Effettua il dump dei 3 database PostgreSQL (`cashly-database`, `nextcloud-db`, `docmost-db`).
- Comprime i dump al volo con `gzip` (`.sql.gz`) risparmiando oltre l'80% dello spazio.
- Salva i file sul RAID in `/mnt/storage/backups/databases/<servizio>/`.
- Elimina automaticamente i backup più vecchi di **14 giorni** (retention configurabile).

### 1. Test manuale dello script
Rendi lo script eseguibile e fai una prova manuale:
```bash
chmod +x scripts/backup-databases.sh
./scripts/backup-databases.sh
```

### 2. Configurazione del Cron Job
Apri il crontab del tuo utente sul server:
```bash
crontab -e
```

Aggiungi la seguente riga per eseguire il backup ogni notte alle **03:00**:
```cron
0 3 * * * /mnt/storage/projects/server-raspberry-pi/scripts/backup-databases.sh >> /mnt/storage/backups/databases/db_backup.log 2>&1
```

---

## 🔄 Procedura di Ripristino (Restore da `.sql.gz`)

I backup compressi possono essere ripristinati direttamente senza doverli decomprimere prima su disco:

### 💰 Cashly
```bash
# Decomprime e invia direttamente a psql
gunzip -c /mnt/storage/backups/databases/cashly/cashly_YYYYMMDD_HHMMSS.sql.gz | docker exec -i cashly-database psql -U user -d cashly_prod
```

### 📂 Nextcloud
```bash
gunzip -c /mnt/storage/backups/databases/nextcloud/nextcloud_YYYYMMDD_HHMMSS.sql.gz | docker exec -i nextcloud-db psql -U nextcloud -d nextcloud
```

### 📝 Docmost
```bash
gunzip -c /mnt/storage/backups/databases/docmost/docmost_YYYYMMDD_HHMMSS.sql.gz | docker exec -i docmost-db psql -U docmost_admin -d docmost_db
```

---

## 🛠️ Backup Manuale "Una Tantum"

Se desideri effettuare un dump manuale al volo:

### Cashly (solo dati, esclusa cronologia migrazioni EF)
```bash
docker exec cashly-database pg_dump -U user -d cashly_prod -a --column-inserts --exclude-table "\"__EFMigrationsHistory\"" > backup_cashly_data.sql
```

### Nextcloud
```bash
docker exec nextcloud-db pg_dump -U nextcloud -d nextcloud > backup_nextcloud.sql
```

### Docmost
```bash
docker exec docmost-db pg_dump -U docmost_admin -d docmost_db > backup_docmost.sql
```
