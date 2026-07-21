# PostgreSQL Backup and Restore

This guide covers the backup and restore procedures for PostgreSQL databases used in the projects.

## 💰 Cashly (Database: `cashly-database`)

### Backup
Export data only, excluding the Entity Framework migration history:
```bash
docker exec cashly-database pg_dump -U user -d cashly_prod -a --column-inserts --exclude-table "\"__EFMigrationsHistory\"" > backup_cashly_data.sql
```

### Restore
Restore the exported data:
```bash
docker exec -i cashly-database psql -U user -d cashly_prod < backup_cashly_data.sql
```

---

## 📂 Nextcloud (Database: `nextcloud-db`)

### Backup
Export the entire Nextcloud database:
```bash
docker exec nextcloud-db pg_dump -U nextcloud -d nextcloud > backup_nextcloud.sql
```

### Restore
Restore the Nextcloud database:
```bash
docker exec -i nextcloud-db psql -U nextcloud -d nextcloud < backup_nextcloud.sql
```
