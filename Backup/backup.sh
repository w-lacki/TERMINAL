#!/bin/bash
set -e
set -o pipefail

export PGPASSWORD="$POSTGRES_PASSWORD"

if [ -z "$RESTIC_GDRIVE_ROOT_FOLDER_ID" ]; then
    echo "[BACKUP] [GDRIVE] Missing Google Drive folder ID."
    exit 1
fi

echo "[BACKUP] [GDRIVE] Starting backup..."
GDRIVE_REPO="rclone:gdrive:terminal-backup"

if ! restic -r "$GDRIVE_REPO" snapshots > /dev/null 2>&1; then
    echo "[BACKUP] [GDRIVE] Initializing repository..."
    restic -r "$GDRIVE_REPO" init
fi

echo "[BACKUP] [GDRIVE] Streaming database dump..."
pg_dump -U "$POSTGRES_USER" -h database -d "$POSTGRES_DB" \
    | restic -r "$GDRIVE_REPO" backup --host terminal --stdin --stdin-filename terminal_db.sql
restic -r "$GDRIVE_REPO" forget --host terminal --keep-hourly 24 --keep-daily 7 --keep-monthly 6 --prune

if [ -z "$RESTIC_SFTP_HOST" ] || [ -z "$RESTIC_SFTP_USER" ] || [ -z "$RESTIC_SFTP_REPO_PATH" ] || [ -z "$RESTIC_SFTP_KEY_PATH" ]; then
    echo "[BACKUP] [SFTP] Missing SFTP configuration."
    exit 1
fi

echo "[BACKUP] [SFTP] Starting backup..."
SFTP_REPO="sftp:${RESTIC_SFTP_USER}@${RESTIC_SFTP_HOST}:${RESTIC_SFTP_REPO_PATH}"
SFTP_ARGS="-i /auth/id_rsa -o StrictHostKeyChecking=no -p ${RESTIC_SFTP_PORT:-22}"

if ! restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" snapshots > /dev/null 2>&1; then
    echo "[BACKUP] [SFTP] Initializing repository..."
    restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" init
fi

echo "[BACKUP] [SFTP] Streaming database dump..."
pg_dump -U "$POSTGRES_USER" -h database -d "$POSTGRES_DB" \
    | restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" backup --host terminal --stdin --stdin-filename terminal_db.sql
restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" forget --host terminal --keep-hourly 24 --keep-daily 7 --keep-monthly 6 --prune
