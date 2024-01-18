#!/bin/bash

send_discord_notification() {
    local message=$1
    local color=$2

    # Check if we should send discord notifications
    if [ -n "$DISCORD_WEB_HOOK" ]; then
        curl \
            -H "Content-Type: application/json" \
            -d "{ \"content\":\"\", \"embeds\":[{ \"title\":\"${PROGRAM_NAME}\", \"description\":\"${message}\", \"color\":${color}} ]}" \
            $DISCORD_WEB_HOOK
    fi
}

check_required_programs() {
    local requirements_file=$1
    local missing=0
    local optional_missing=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        program=${line#\*}
        is_optional=false

        if [[ "$line" == \** ]]; then
            is_optional=true
        fi

        if ! command -v "$program" &> /dev/null; then
            if [ "$is_optional" = true ]; then
                echo -e "${YELLOW}Warning: Optional program '$program' is not installed.${NC}" >&2
                optional_missing=1
            else
                echo -e "${RED}Error: Required program '$program' is not installed.${NC}" >&2
                missing=1
            fi
        fi
    done < "$requirements_file"

    if [ $missing -ne 0 ]; then
        local ERR_MSG="One or more required programs are missing."
        send_discord_notification "$ERR_MSG" "16711680"
        echo -e "${RED}$ERR_MSG${NC}" >&2
        exit 1
    elif [ $optional_missing -ne 0 ]; then
        local WARN_MSG="One or more optional programs are missing."
        send_discord_notification "$WARN_MSG" "16776960" # Yellow color code
        echo -e "${YELLOW}$WARN_MSG${NC}" >&2
    fi
}

# Logging

success() {
    echo -e "${GREEN}Success: $1${NC}"
}

log() {
    echo -e "${NC}$1${NC}"
}

warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}