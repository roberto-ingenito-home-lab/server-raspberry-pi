#!/usr/bin/env bash
# ==============================================================================
# Script di Backup Automatico Database PostgreSQL (Docker)
# Servizi: Cashly, Nextcloud, Docmost
# ==============================================================================

set -uo pipefail

# --- CONFIGURAZIONE ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${REPO_DIR}/.env"

# Cartella di destinazione dei backup (default su RAID)
BACKUP_DIR="${BACKUP_DIR:-/mnt/storage/backups/databases}"

# Giorni di conservazione dei backup (retention policy)
RETENTION_DAYS="${RETENTION_DAYS:-14}"

# Timestamp per i file di backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Carica le variabili da .env se presente
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
fi

# Credenziali con fallback ai default dell'ambiente
CASHLY_CONTAINER="cashly-database"
CASHLY_USER="${CASHLY_POSTGRES_USER:-user}"
CASHLY_DB="${CASHLY_POSTGRES_DB:-cashly_prod}"

NEXTCLOUD_CONTAINER="nextcloud-db"
NEXTCLOUD_USER="nextcloud"
NEXTCLOUD_DB="nextcloud"

DOCMOST_CONTAINER="docmost-db"
DOCMOST_USER="${DOCMOST_DB_USER:-docmost_admin}"
DOCMOST_DB="${DOCMOST_DB_NAME:-docmost_db}"

# --- FUNZIONI DI LOGGING ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*"
}

# --- FUNZIONE DI BACKUP SINGOLO DATABASE ---
backup_postgres() {
    local container="$1"
    local user="$2"
    local db="$3"
    local service_name="$4"
    local extra_args="${5:-}"

    local target_dir="${BACKUP_DIR}/${service_name}"
    local backup_file="${target_dir}/${service_name}_${TIMESTAMP}.sql.gz"

    mkdir -p "$target_dir"

    # Verifica che il container sia in esecuzione
    if ! docker ps --format '{{.Names}}' | grep -Eq "^${container}\$"; then
        log_error "Container '${container}' non in esecuzione. Backup di '${service_name}' saltato."
        return 1
    fi

    log "Avvio backup: ${service_name} (Database: ${db}, Container: ${container})..."

    # Esegue pg_dump e comprime al volo con gzip
    # shellcheck disable=SC2086
    if docker exec "$container" pg_dump -U "$user" -d "$db" $extra_args | gzip -9 > "$backup_file"; then
        local file_size
        file_size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup ${service_name} completato: ${backup_file} (${file_size})"
    else
        log_error "Fallito dump per '${service_name}'!"
        rm -f "$backup_file"
        return 1
    fi
}

# --- FUNZIONE ROTAZIONE (PULIZIA VECCHI BACKUP) ---
clean_old_backups() {
    log "Avvio pulizia backup più vecchi di ${RETENTION_DAYS} giorni in ${BACKUP_DIR}..."
    local count
    count=$(find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" | wc -l)

    if [[ "$count" -gt 0 ]]; then
        find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -print -delete
        log_success "Eliminati ${count} file obsoleti."
    else
        log "Nessun file obsoleto da eliminare."
    fi
}

# --- ESECUZIONE ---
main() {
    log "=========================================================="
    log "Inizio procedura di backup database"
    log "=========================================================="

    mkdir -p "$BACKUP_DIR"

    local errors=0

    # 1. Cashly
    backup_postgres "$CASHLY_CONTAINER" "$CASHLY_USER" "$CASHLY_DB" "cashly" || ((errors++))

    # 2. Nextcloud
    backup_postgres "$NEXTCLOUD_CONTAINER" "$NEXTCLOUD_USER" "$NEXTCLOUD_DB" "nextcloud" || ((errors++))

    # 3. Docmost
    backup_postgres "$DOCMOST_CONTAINER" "$DOCMOST_USER" "$DOCMOST_DB" "docmost" || ((errors++))

    # 4. Pulizia vecchi backup
    clean_old_backups

    log "=========================================================="
    if [[ $errors -eq 0 ]]; then
        log_success "Tutti i backup sono stati completati con successo."
    else
        log_error "Completato con ${errors} errore/i. Controlla i log precedenti."
    fi
    log "=========================================================="

    return $errors
}

main "$@"
