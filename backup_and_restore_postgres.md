# Backup e Ripristino PostgreSQL

Questa guida copre le procedure di backup e ripristino per i database PostgreSQL utilizzati nei progetti.

## 💰 Cashly (Database: `cashly-database`)

### Backup
Esporta solo i dati, escludendo la cronologia delle migrazioni di Entity Framework:
```bash
docker exec cashly-database pg_dump -U user -d cashly_prod -a --column-inserts --exclude-table "\"__EFMigrationsHistory\"" > backup_cashly_data.sql
```

### Ripristino
Ripristina i dati esportati:
```bash
docker exec -i cashly-database psql -U user -d cashly_prod < backup_cashly_data.sql
```

---

## 📂 Nextcloud (Database: `nextcloud-db`)

### Backup
Esporta l'intero database di Nextcloud:
```bash
docker exec nextcloud-db pg_dump -U nextcloud -d nextcloud > backup_nextcloud.sql
```

### Ripristino
Ripristina il database di Nextcloud:
```bash
docker exec -i nextcloud-db psql -U nextcloud -d nextcloud < backup_nextcloud.sql
```
