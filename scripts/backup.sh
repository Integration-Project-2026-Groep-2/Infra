#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="${BACKUP_DIR:-"/var/backups/infra"}"
OUT_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$OUT_DIR"

log() {
  printf '%s %s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$*"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$1"
}

ensure_container() {
  if ! container_running "$1"; then
    log "Skip $1 (not running)"
    return 1
  fi
  return 0
}

backup_mariadb() {
  local container="$1"
  local name="$2"

  ensure_container "$container" || return 0

  log "Dump MariaDB: $name"
  docker exec "$container" sh -c 'mariadb-dump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' \
    > "$OUT_DIR/${name}.sql"
}

backup_postgres() {
  local container="$1"
  local name="$2"

  ensure_container "$container" || return 0

  log "Dump Postgres: $name"
  docker exec "$container" sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    > "$OUT_DIR/${name}.sql"
}

backup_rabbitmq_definitions() {
  local container="rabbitmq_management"

  ensure_container "$container" || return 0

  log "Export RabbitMQ definitions"
  docker exec "$container" rabbitmqctl export_definitions /tmp/definitions.json
  docker cp "$container:/tmp/definitions.json" "$OUT_DIR/rabbitmq_definitions.json"
  docker exec "$container" rm -f /tmp/definitions.json
}

backup_volume() {
  local volume="$1"

  if ! docker volume inspect "$volume" >/dev/null 2>&1; then
    log "Skip volume $volume (not found)"
    return 0
  fi

  log "Backup volume: $volume"
  docker run --rm \
    -v "$volume:/data:ro" \
    -v "$OUT_DIR:/backup" \
    alpine:3.20 \
    sh -c "cd /data && tar -czf /backup/${volume}.tar.gz ."
}

log "Backup start: $OUT_DIR"

# MariaDB
backup_mariadb billing_db billing_db
backup_mariadb mailing_db mailing_db
backup_mariadb frontend_db frontend_db

# Postgres
backup_postgres kassa_db kassa_db
backup_postgres infra_postgres_planning planning_db

# RabbitMQ
backup_rabbitmq_definitions

# Volume backups (configure via VOLUME_BACKUPS env var)
VOLUME_BACKUPS_DEFAULT="elasticsearch rabbitmq_data drupal_sites drupal_themes drupal_profiles odoo_web_data_kassa"
VOLUME_BACKUPS="${VOLUME_BACKUPS:-$VOLUME_BACKUPS_DEFAULT}"

for volume in $VOLUME_BACKUPS; do
  backup_volume "$volume"
done

log "Backup complete"
