## About

This script has been written to backup a `vaultwarden` docker-compose instance, this is how I run my own service on my own server, this backup script will target the `data` folder and of course will also use `sqlite` to create a `.backup` of the `db.sqlite3` file, to ensure safety.

## Requirements

### [gdrive](https://github.com/glotlabs/gdrive)
gdrive is a command line application for interacting with Google Drive.

## Overview
Environment: Docker Compose

Docker Compose File:
```yml
version: '3'

services:
  bitwarden:
    image: vaultwarden/server:latest
    ports:
      - 127.0.0.1:90:80
      - 127.0.0.1:91:3012
    user: "${UID}:${GID}"
    volumes:
      - ./data:/data
    restart: unless-stopped
    environment:
      WEBSOCKET_ENABLED: 'true'
      SMTP_HOST: "smtp.gmail.com"
      SMTP_FROM: "xxx@local.lan"
      SMTP_PORT: 587
      SMTP_SECURITY: "starttls"
      SMTP_USERNAME: "xxx@local.lan"
      SMTP_PASSWORD: "xxx"
      DOMAIN: "https://pass.yourdomain.lan"
```

Directory Structure
```bash
/path/to/your/service
├── data
│   ├── attachments
│   ├── db.sqlite3 # Your important database
│   ├── db.sqlite3-shm
│   ├── db.sqlite3-wal
│   ├── icon_cache
│   ├── rsa_key.pem
│   ├── rsa_key.pub.pem
│   ├── sends
│   └── tmp
└── docker-compose.yaml
```

## Restoration Procedure
Simply unzip the backup file, plop the docker-compose with the correct parameters into the same folder and run it, it should pick right back where it was, but in case the database did get corrupt or broken because the backup was running during an operation, simply remote the `db.sqlite3-sh` and `db.sqlite3-wa` files, and replace the `db.sqplite3` with the one from the zip's top-level, this should work just fine.

Worst case scenario, restore the database from a different point and it will definitely work.