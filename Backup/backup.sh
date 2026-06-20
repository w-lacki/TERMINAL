#!/bin/bash
set -e

echo "[BACKUP] Dumping database to a file..."
BACKUP_FILE="backups/terminal_db.sql"
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_dump -U "$POSTGRES_USER" -h database -d "$POSTGRES_DB" -f "$BACKUP_FILE"

if [ -n "$RESTIC_SFTP_HOST" ] && [ -n "$RESTIC_SFTP_USER" ]; then
    echo "[BACKUP] [SFTP] Starting backup to SFTP backend..."
    
    SFTP_REPO="sftp:${RESTIC_SFTP_USER}@${RESTIC_SFTP_HOST}:${RESTIC_SFTP_REPO_PATH}"
    SFTP_ARGS="-i /auth/id_rsa -o StrictHostKeyChecking=no -p $RESTIC_SFTP_PORT"

    if ! restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" snapshots > /dev/null 2>&1; then
        echo "[BACKUP] [SFTP] Repository not found. Initializing new repository..."
        restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" init
    fi

    restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" backup --host terminal "$BACKUP_FILE"
    restic -r "$SFTP_REPO" -o sftp.args="$SFTP_ARGS" forget --host terminal --keep-hourly 24 --keep-daily 7 --keep-monthly 6 --prune   
    echo "[BACKUP] [SFTP] Backup and retention policy completed."
else
    echo "[BACKUP] [SFTP] Skipping SFTP backup (credentials not provided)."
fi

if [ -n "$RESTIC_GDRIVE_RCLONE_REMOTE" ] && [ -n "$GDRIVE_REPO_PATH" ]; then
    echo "[BACKUP] [GDRIVE] Starting backup to Google Drive..."

    GDRIVE_REPO="rclone:${GDRIVE_RCLONE_REMOTE}:${GDRIVE_REPO_PATH}"

    if ! restic -r "$RESTIC_GDRIVE_REPO" snapshots > /dev/null 2>&1; then
        echo "[BACKUP] [GDRIVE] Repository not found. Initializing new repository..."
        restic -r "$RESTIC_GDRIVE_REPO" init
    fi

    restic -r "$RESTIC_GDRIVE_REPO" backup --host terminal "$BACKUP_FILE"
    restic -r "$RESTIC_GDRIVE_REPO" forget --host terminal --keep-hourly 24 --keep-daily 7 --keep-monthly 6 --prune
    echo "[BACKUP] [GDRIVE] Backup and retention policy completed."
else
    echo "[BACKUP] [GDRIVE] Skipping Google Drive backup (credentials not provided)."
fi

echo "[BACKUP] Deleting local database dump"
rm "$BACKUP_FILE"
