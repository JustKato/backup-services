#!/bin/bash

# Preloader
# Determine the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

PROGRAM_NAME="Gitea Backup Script"

### [ Imports ] ###
# Import Colors
source "$SCRIPT_DIR/../lib/colors.sh"
# Import configuration
source "$SCRIPT_DIR/config.sh"
# Import Functions
source "$SCRIPT_DIR/../lib/functions.sh"

### [ Functions ] ###

backup_from_docker() {
    # Reference to the gitea container id
    GITEA_DOCKER_CONTAINER=$(docker ps -qf name="${GITEA_CONTAINER_NAME}")

    # Run the backup process
    if docker exec -w $GITEA_BACKUP_CONTAINER_LOCATION -u git $GITEA_DOCKER_CONTAINER bash -c "/usr/local/bin/gitea dump -c \"$GITEA_CONF_PATH\""; then
        log "Gitea backup created successfully."
    else
        error "Failed to create Gitea backup."
        send_discord_notification "Failed to create Gitea backup."
        exit 1
    fi

    # Determine the path to the output file
    BACKUP_FILE=$(ls -Art $BACKUP_SOURCE_PATH/gitea-dump-*.zip | tail -n 1)

    if [ -z "$BACKUP_FILE" ]; then
        error "Backup file not found."
        send_discord_notification "Backup file not found."
        exit 1
    fi

    log "Backup file $BACKUP_FILE created."
}

delete_old_local_backups() {
    # Keep only the last $KEEP_BACKUP_COUNT backups
    if [ -n "$KEEP_BACKUP_COUNT" ]; then
        # Get the number of backup files
        BACKUP_COUNT=$(ls -1 $BACKUP_SOURCE_PATH/gitea-dump-*.zip | wc -l)

        # Check if the current number of backups exceeds the limit
        if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUP_COUNT" ]; then
            log "Removing old backups."
            # Remove the oldest files
            ls -1tr $BACKUP_SOURCE_PATH/gitea-dump-*.zip | head -n -$KEEP_BACKUP_COUNT | xargs -d '\n' rm -f
        fi
    fi
}

# Google Drive

upload_to_google_drive() {
    if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ] && [ -n "$BACKUP_FILE" ]; then
        log "Uploading backup zip to google drive."

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
        GCLOUD_BACKUPS=$(gdrive files list --parent $GOOGLE_DRIVE_FOLDER_ID --skip-header --order-by "createdTime asc" | awk '{print $1}')
        BACKUP_COUNT=$(echo "$GCLOUD_BACKUPS" | wc -l)

        log "Deleting old gdrive backups."

        if [ "$BACKUP_COUNT" -gt "$GOOGLE_DRIVE_KEEP_BACKUP_COUNT" ]; then
            DELETE_COUNT=$((BACKUP_COUNT - GOOGLE_DRIVE_KEEP_BACKUP_COUNT))
            DELETE_BACKUPS=$(echo "$GCLOUD_BACKUPS" | head -n "$DELETE_COUNT")

            echo "$DELETE_BACKUPS" | while read -r BACKUP_ID; do
                if [ -n "$BACKUP_ID" ]; then
                    gdrive files delete $BACKUP_ID
                    if [ $? -eq 0 ]; then
                        local MSG_X="Deleted old backup with ID $BACKUP_ID from Google Drive."
                        log "$MSG_X"
                        send_discord_notification "$MSG_X" "16776960"
                    else
                        local MSG_X="Failed to delete backup with ID $BACKUP_ID from Google Drive."
                        log "$MSG_X"
                        send_discord_notification "$MSG_X" "16711680"
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
send_discord_notification "Starting Gitea backup..." "16776960" # Yellow color

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
send_discord_notification "Backup process completed."