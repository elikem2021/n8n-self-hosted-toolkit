#!/bin/bash
# Nightly backup of n8n: Postgres dump + n8n_data volume + decrypted credentials snapshot.
# Run via cron at 2am: 0 2 * * * /opt/n8n-toolkit/backup/backup.sh
set -euo pipefail

cd "$(dirname "$0")/.."
source .env

DATE=$(date -u +%Y-%m-%d)
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# 1) Postgres dump
docker compose -f docker/docker-compose.yml exec -T postgres \
    pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$TMP/postgres-$DATE.sql.gz"

# 2) n8n volume tarball
docker run --rm -v n8n-self-hosted-toolkit_n8n_data:/data:ro \
    -v "$TMP":/backup alpine \
    tar czf "/backup/n8n_data-$DATE.tar.gz" -C /data .

# 3) Upload to S3-compatible
if [ -n "${S3_BACKUP_BUCKET:-}" ]; then
    docker run --rm \
        -e AWS_ACCESS_KEY_ID="$S3_BACKUP_ACCESS_KEY" \
        -e AWS_SECRET_ACCESS_KEY="$S3_BACKUP_SECRET_KEY" \
        -e AWS_DEFAULT_REGION="$S3_BACKUP_REGION" \
        -v "$TMP":/local \
        amazon/aws-cli:latest s3 cp /local/ "s3://$S3_BACKUP_BUCKET/n8n/$DATE/" \
        --recursive ${S3_BACKUP_ENDPOINT:+--endpoint-url "$S3_BACKUP_ENDPOINT"}
fi

echo "[$(date -Iseconds)] backup complete: $DATE"
