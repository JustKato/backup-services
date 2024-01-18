#!/bin/bash

# Preloader
# Determine the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

### [ Variables ] ###
# Import configuration
source "$SCRIPT_DIR/config.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

### [ Functions ] ###
send_discord_notification() {
    local message=$1
    local color=$2

    # Check if we should send discord notifications
    if [ -n "$DISCORD_WEB_HOOK" ]; then
        curl \
            -H "Content-Type: application/json" \
            -d "{ \"content\":\"\", \"embeds\":[{ \"title\":\"Vaultwarden Backup\", \"description\":\"${message}\", \"color\":${color}} ]}" \
            $DISCORD_WEB_HOOK
    fi
}

get_7zip_password() {
    /home/danlegt/services/backup_scripts/bitwarden/bitwarden_backup_password_decrypt.sh
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

delete_old_backups() {
    echo -e "${YELLOW}Deleting backups older than ${BACKUP_RETENTION_DAYS} days...${NC}"
    find $BACKUP_DIR -type f -name "vaultwarden-backup-*.7z" -mtime +$BACKUP_RETENTION_DAYS -exec rm {} \;
    echo -e "${GREEN}Old backups deleted${NC}"
}

### [ Main ] ###
echo -e "${YELLOW}Starting Vaultwarden backup...${NC}"
send_discord_notification "Starting Vaultwarden backup..." "16776960" # Yellow color

backup_sqlite_database
compress_and_encrypt_backup
delete_old_backups