#!/bin/bash

##########################
# [ Base Configuration ] #
##########################

# The target directory to write the .7z files to
BACKUP_DIR="/path/to/backups"
# THe vaultwarden data directory
VAULTWARDEN_DATA_DIR="/path/to/bitwarden/data"
# The amount of days to keep data retention locally for
BACKUP_RETENTION_DAYS=30

# [ DISCORD ]
# A discord web hook to send administrative messages through | Leave empty to not send webhook messages
DISCORD_WEB_HOOK=""

# [ Google Drive ]
# The id of the folder to keep the backups synchronized with
GOOGLE_DRIVE_FOLDER_ID=
# The amount of backups to be kept in google drive, this has nothing to do with time it's just a set number
# and will, logically, remove the oldest first.
GOOGLE_DRIVE_KEEP_BACKUP_COUNT=16

#########################
# [ Generative Config ] #
#########################
# These shouldn't be generally changed

# The path to the sqlite3 database to properly backup
SQLITE_DB_PATH="$VAULTWARDEN_DATA_DIR/db.sqlite3"
# The path to write the sqlite backup to
SQLITE_BACKUP_PATH="$BACKUP_DIR/database_backup"
# The backup file's location, this is automatically generated but feel free to change
BACKUP_FILE="$BACKUP_DIR/vaultwarden_backup_$(date '+%Y%m%d_%H%M%S').7z"