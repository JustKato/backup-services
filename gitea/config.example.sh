
# The name of the gitea container, this is required.
GITEA_CONTAINER_NAME="^gitea_app$" # Please keep in mind this is a regex, so if you are putting in the exact name prepend with ^ and append with $
# An absolute path to the gitea app.ini from within the docker container
GITEA_CONF_PATH=/data/gitea/conf/app.ini
# The path where WITHING THE CONTAINER the dump will be placed
GITEA_BACKUP_CONTAINER_LOCATION=/backups

# The path that was mounted for gitea to push backups to
BACKUP_SOURCE_PATH=/home/x/services/gitea/backups
# Define the number of backups to keep (e.g., keep the latest 7 backups)
KEEP_BACKUP_COUNT=3

# Discord Settings
DISCORD_WEBHOOK=

# Google Drive Settings
GOOGLE_DRIVE_FOLDER_ID=
