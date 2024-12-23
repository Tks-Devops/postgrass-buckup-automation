#!/bin/bash

# Variables
PGUSER="myuser"
PGPASSWORD="ram"
PGHOST="localhost"
BACKUP_DIR="/tmp/pg_backups"
S3_BUCKET="my-pgsql-backups"
DATE=$(date +"%Y-%m-%d")

# Export PostgreSQL password for non-interactive authentication
export PGPASSWORD=$PGPASSWORD

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get list of databases
databases=$(psql -U $PGUSER -h $PGHOST -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Loop through databases and back them up
for db in $databases; do
    echo "Backing up database: $db"
    BACKUP_FILE="$BACKUP_DIR/${db}_${DATE}.sql.gz"
    
    # Backup and compress
    pg_dump -U $PGUSER -h $PGHOST $db | gzip > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Backup successful for $db. Uploading to S3..."
        
        # Upload to S3
        aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$db/"
        
        if [ $? -eq 0 ]; then
            echo "Upload successful for $db."
        else
            echo "Upload failed for $db."
        fi
    else
        echo "Backup failed for $db."
    fi
done

# Cleanup: Uncomment to delete local backups after upload
# rm -rf "$BACKUP_DIR"

echo "All backups completed."

