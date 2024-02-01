#!/bin/bash

# Preloader
# Determine the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROGRAM_NAME="PostgreSQL Backup"

### [ Imports ] ###
# Import Colors
source "$SCRIPT_DIR/../lib/colors.sh"
# Import configuration
source "$SCRIPT_DIR/config.sh"
# Import Functions
source "$SCRIPT_DIR/../lib/functions.sh"

### [ Functions ] ###

backup_from_docker() {
    # Reference to the postgres container id
    POSTGRES_DOCKER_CONTAINER=$(docker ps -qf name="${POSTGRES_CONTAINER_NAME}")

    # Ensure the backup directory exists
    mkdir -p "${BACKUP_SOURCE_PATH}"

    # The name of the backup file
    BACKUP_FILE="${BACKUP_SOURCE_PATH}/pg_dump_$(date +%Y-%m-%d_%H%M%S).sql.gz"

    # Run the backup process
    if PGPASSWORD=$POSTGRES_PASSWORD docker exec $POSTGRES_DOCKER_CONTAINER pg_dump -U $POSTGRES_USER -h localhost $POSTGRES_DB | gzip > $BACKUP_FILE; then
        log "PostgreSQL backup created successfully."
    else
        error "Failed to create PostgreSQL backup."
        send_discord_notification "Failed to create PostgreSQL backup." "16711680"
        exit 1
    fi

    log "Backup file $BACKUP_FILE created."
}

delete_old_local_backups() {
    # Keep only the last $KEEP_BACKUP_COUNT backups
    if [ -n "$KEEP_BACKUP_COUNT" ]; then
        # Get the number of backup files
        BACKUP_COUNT=$(ls -1 $BACKUP_SOURCE_PATH/pg_dump_*.sql.gz | wc -l)

        # Check if the current number of backups exceeds the limit
        if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUP_COUNT" ]; then
            log "Removing old backups."
            # Remove the oldest files
            ls -1tr $BACKUP_SOURCE_PATH/pg_dump_*.sql.gz | head -n -$KEEP_BACKUP_COUNT | xargs -d '\n' rm -f
        fi
    fi
}

# Google Drive

upload_to_google_drive() {
    if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ] && [ -n "$BACKUP_FILE" ]; then
        log "Uploading backup to google drive."

        gdrive files upload --parent $GOOGLE_DRIVE_FOLDER_ID $BACKUP_FILE
        if [ $? -eq 0 ]; then
            log "Backup file uploaded to Google Drive."
            send_discord_notification "Backup file uploaded to Google Drive." "65280"
        else
            error "Failed to upload backup file to Google Drive."
            send_discord_notification "Failed to upload backup file to Google Drive." "16711680"
            exit 1
        fi
    else
        log "Google Drive upload not configured. Skipping."
    fi
}

delete_old_gdrive_backups() {
    if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ] && [ -n "$GOOGLE_DRIVE_KEEP_BACKUP_COUNT" ]; then
        GCLOUD_BACKUPS=$(gdrive files list --query "'$GOOGLE_DRIVE_FOLDER_ID' in parents" --order "createdTime" --no-header | awk '{print $1}')
        BACKUP_COUNT=$(echo "$GCLOUD_BACKUPS" | wc -l)

        log "Deleting old gdrive backups."

        if [ "$BACKUP_COUNT" -gt "$GOOGLE_DRIVE_KEEP_BACKUP_COUNT" ]; then
            DELETE_COUNT=$((BACKUP_COUNT - GOOGLE_DRIVE_KEEP_BACKUP_COUNT))
            DELETE_BACKUPS=$(echo "$GCLOUD_BACKUPS" | head -n "$DELETE_COUNT")

            echo "$DELETE_BACKUPS" | while read -r BACKUP_ID; do
                if [ -n "$BACKUP_ID" ]; then
                    gdrive files delete $BACKUP_ID
                    if [ $? -eq 0 ]; then
                        local MSG_X="Deleted old backup with ID ${BACKUP_ID} from Google Drive."
                        log "${MSG_X}"
                        send_discord_notification "${MSG_X}" "16776960"
                    else
                        local MSG_X="Failed to delete backup with ID $BACKUP_ID from Google Drive."
                        log "${MSG_X}"
                        send_discord_notification "${MSG_X}" "16711680"
                    fi
                fi
            done
        else
            log "No old backups to delete."
        fi
    else
        log "Google Drive cleanup not configured. Skipping."
    fi
}

### [ Main ] ###
echo -e "${YELLOW}Starting ${PROGRAM_NAME}...${NC}"
send_discord_notification "Starting PostgreSQL backup..." "16776960" # Yellow color

check_required_programs "$SCRIPT_DIR/required_programs.txt"

# Run the main backup process
backup_from_docker

# Run google drive backup
upload_to_google_drive

# Delete old files
delete_old_local_backups
delete_old_gdrive_backups

# Final message
log "Backup process completed."
send_discord_notification "Backup process completed." "65280"
