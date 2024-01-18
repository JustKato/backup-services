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
get_7zip_password() {
    $SCRIPT_DIR/bitwarden_backup_password_decrypt.sh
}

backup_sqlite_database() {
    echo -e "${YELLOW}Backing up SQLite database...${NC}"
    sqlite3 $SQLITE_DB_PATH ".backup '$SQLITE_BACKUP_PATH'"
    if [ $? -ne 0 ]; then
        echo -e "${RED}SQLite database backup failed${NC}"
        send_discord_notification "SQLite database backup failed" "16711680" # Red color
        exit 1
    fi
}

compress_and_encrypt_backup() {
    echo -e "${YELLOW}Compressing and encrypting backup...${NC}"
    7zz a -p"$(get_7zip_password)" -mhe=on -t7z $BACKUP_FILE $VAULTWARDEN_DATA_DIR $SQLITE_BACKUP_PATH
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Backup successful: ${BACKUP_FILE}${NC}"
        send_discord_notification "Backup successful: ${BACKUP_FILE}" "65280" # Green color
    else
        echo -e "${RED}Backup failed${NC}"
        send_discord_notification "Backup failed" "16711680" # Red color
        exit 1
    fi
}

delete_old_local_backups() {
    echo -e "${YELLOW}Deleting local backups older than ${BACKUP_RETENTION_DAYS} days...${NC}"
    find $BACKUP_DIR -type f -name "vaultwarden-backup-*.7z" -mtime +$BACKUP_RETENTION_DAYS -exec rm {} \;
    echo -e "${GREEN}Old backups deleted${NC}"
}

# Google Drive

upload_to_google_drive() {
    if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ] && [ -n "$BACKUP_FILE" ]; then
        echo -e "${YELLOW}Uploading backup zip to google drive.${NC}"

        gdrive files upload --parent $GOOGLE_DRIVE_FOLDER_ID $BACKUP_FILE
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}Backup file uploaded to Google Drive.${NC}"
            send_discord_notification "Backup file uploaded to Google Drive." "65280"
        else
            echo -e "${RED}Failed to upload backup file to Google Drive.${NC}"
            send_discord_notification "Failed to upload backup file to Google Drive." "16711680"
            exit 1
        fi
    else
        echo -e "${YELLOW}Google Drive upload not configured. Skipping.${NC}"
    fi
}

delete_old_gdrive_backups() {
    if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ] && [ -n "$GOOGLE_DRIVE_KEEP_BACKUP_COUNT" ]; then
        GCLOUD_BACKUPS=$(gdrive files list --parent $GOOGLE_DRIVE_FOLDER_ID --skip-header --order-by "createdTime asc" | awk '{print $1}')
        BACKUP_COUNT=$(echo "$GCLOUD_BACKUPS" | wc -l)

        echo -e "${YELLOW}Deleting old gdrive backups.${NC}"

        if [ "$BACKUP_COUNT" -gt "$GOOGLE_DRIVE_KEEP_BACKUP_COUNT" ]; then
            DELETE_COUNT=$((BACKUP_COUNT - GOOGLE_DRIVE_KEEP_BACKUP_COUNT))
            DELETE_BACKUPS=$(echo "$GCLOUD_BACKUPS" | head -n "$DELETE_COUNT")

            echo "$DELETE_BACKUPS" | while read -r BACKUP_ID; do
                if [ -n "$BACKUP_ID" ]; then
                    gdrive files delete $BACKUP_ID
                    if [ $? -eq 0 ]; then
                        local MSG_X="Deleted old backup with ID $BACKUP_ID from Google Drive."
                        echo -e "$MSG_X"
                        send_discord_notification "$MSG_X" "16776960"
                    else
                        local MSG_X="${RED}Failed to delete backup with ID $BACKUP_ID from Google Drive.${NC}"
                        echo -e "$MSG_X"
                        send_discord_notification "$MSG_X" "16711680"
                    fi
                fi
            done
        else
            echo -e "${YELLOW}No old backups to delete.${NC}"
        fi
    else
        echo -e "${YELLOW}Google Drive cleanup not configured. Skipping.${NC}"
    fi
}

### [ Main ] ###
echo -e "${YELLOW}Starting ${PROGRAM_NAME}...${NC}"
send_discord_notification "Starting Vaultwarden backup..." "16776960" # Yellow color

check_required_programs "$SCRIPT_DIR/required_programs.txt"

backup_sqlite_database
compress_and_encrypt_backup

upload_to_google_drive

delete_old_local_backups
delete_old_gdrive_backups