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

### [ Main ] ###
echo -e "${YELLOW}Starting ${PROGRAM_NAME}...${NC}"
send_discord_notification "Starting Vaultwarden backup..." "16776960" # Yellow color

check_required_programs "$SCRIPT_DIR/required_programs.txt"

backup_from_docker

# Run google drive backup

# Final message
log "Backup process completed."
send_discord_notification "Backup process completed."