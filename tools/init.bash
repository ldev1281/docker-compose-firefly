#!/usr/bin/env bash
set -Eeuo pipefail

# -------------------------------------
# Firefly III setup script
# -------------------------------------

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
VOL_DIR="${SCRIPT_DIR}/../vol"
BACKUP_TASKS_SRC_DIR="${SCRIPT_DIR}/../etc/limbo-backup/rsync.conf.d"
BACKUP_TASKS_DST_DIR="/etc/limbo-backup/rsync.conf.d"

REQUIRED_TOOLS="docker limbo-backup.bash"
REQUIRED_NETS="proxy-client-firefly"
BACKUP_TASKS="10-firefly.conf.bash"

FIREFLY_POSTGRES_VERSION=15
CURRENT_FIREFLY_VERSION=version-6.4.2

check_requirements() {
    missed_tools=()
    for cmd in $REQUIRED_TOOLS; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missed_tools+=("$cmd")
        fi
    done

    if ((${#missed_tools[@]})); then
        echo "Required tools not found:" >&2
        for cmd in "${missed_tools[@]}"; do
            echo "  - $cmd" >&2
        done
        echo "Hint: run dev-prod-init.recipe from debian-setup-factory" >&2
        echo "Abort"
        exit 127
    fi
}

create_networks() {
    for net in $REQUIRED_NETS; do
        if docker network inspect "$net" >/dev/null 2>&1; then
            echo "Required network already exists: $net"
        else
            echo "Creating required docker network: $net (driver=bridge)"
            docker network create --driver bridge --internal "$net" >/dev/null
        fi
    done
}

create_backup_tasks() {
    for task in $BACKUP_TASKS; do
        src_file="${BACKUP_TASKS_SRC_DIR}/${task}"
        dst_file="${BACKUP_TASKS_DST_DIR}/${task}"

        if [[ ! -f "$src_file" ]]; then
            echo "Warning: backup task not found: $src_file" >&2
            continue
        fi

        cp "$src_file" "$dst_file"
        echo "Created backup task: $dst_file"
    done
}

# Generate secure random defaults
generate_defaults() {
    FIREFLY_POSTGRES_PASSWORD=$(openssl rand -hex 32)
    FIREFLY_APP_KEY="base64:$(openssl rand -base64 32)"
}

# Load existing configuration from .env file
load_existing_env() {
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
}

# Prompt user to confirm or update configuration
prompt_for_configuration() {
    echo "Please enter configuration values (press Enter to keep current/default value):"
    echo ""

    echo "PostgreSQL settings:"

    read -p "FIREFLY_POSTGRES_USER [${FIREFLY_POSTGRES_USER:-firefly}]: " input
    FIREFLY_POSTGRES_USER=${input:-${FIREFLY_POSTGRES_USER:-firefly}}

    read -p "FIREFLY_POSTGRES_PASSWORD [${FIREFLY_POSTGRES_PASSWORD:-password}]: " input
    FIREFLY_POSTGRES_PASSWORD=${input:-${FIREFLY_POSTGRES_PASSWORD:-password}}

    read -p "FIREFLY_POSTGRES_DB [${FIREFLY_POSTGRES_DB:-firefly}]: " input
    FIREFLY_POSTGRES_DB=${input:-${FIREFLY_POSTGRES_DB:-firefly}}

    echo ""
    echo "Firefly III settings:"
    read -p "FIREFLY_APP_HOSTNAME [${FIREFLY_APP_HOSTNAME:-firefly.example.com}]: " input
    FIREFLY_APP_HOSTNAME=${input:-${FIREFLY_APP_HOSTNAME:-firefly.example.com}}

    echo ""
    echo "SMTP settings:"
    read -p "FIREFLY_SMTP_HOST [${FIREFLY_SMTP_HOST:-smtp.mailgun.org}]: " input
    FIREFLY_SMTP_HOST=${input:-${FIREFLY_SMTP_HOST:-smtp.mailgun.org}}

    read -p "FIREFLY_SMTP_PORT [${FIREFLY_SMTP_PORT:-587}]: " input
    FIREFLY_SMTP_PORT=${input:-${FIREFLY_SMTP_PORT:-587}}

    read -p "FIREFLY_SMTP_USER [${FIREFLY_SMTP_USER:-postmaster@sandbox123.mailgun.org}]: " input
    FIREFLY_SMTP_USER=${input:-${FIREFLY_SMTP_USER:-postmaster@sandbox123.mailgun.org}}

    read -p "FIREFLY_SMTP_PASS [${FIREFLY_SMTP_PASS:-password}]: " input
    FIREFLY_SMTP_PASS=${input:-${FIREFLY_SMTP_PASS:-password}}

    read -p "FIREFLY_SMTP_FROM [${FIREFLY_SMTP_FROM:-firefly@sandbox123.mailgun.org}]: " input
    FIREFLY_SMTP_FROM=${input:-${FIREFLY_SMTP_FROM:-firefly@sandbox123.mailgun.org}}

    FIREFLY_VERSION=${CURRENT_FIREFLY_VERSION}
}

confirm_and_save_configuration() {
    CONFIG_LINES=(
        "# PostgreSQL"
        "FIREFLY_POSTGRES_VERSION=${FIREFLY_POSTGRES_VERSION}"
        "FIREFLY_POSTGRES_USER=${FIREFLY_POSTGRES_USER}"
        "FIREFLY_POSTGRES_PASSWORD=${FIREFLY_POSTGRES_PASSWORD}"
        "FIREFLY_POSTGRES_DB=${FIREFLY_POSTGRES_DB}"
        ""
        "# Firefly"
        "FIREFLY_VERSION=${FIREFLY_VERSION}"
        "FIREFLY_APP_KEY=${FIREFLY_APP_KEY}"
        "FIREFLY_APP_HOSTNAME=${FIREFLY_APP_HOSTNAME}"
        ""
        "# SMTP"
        "FIREFLY_SMTP_HOST=${FIREFLY_SMTP_HOST}"
        "FIREFLY_SMTP_PORT=${FIREFLY_SMTP_PORT}"
        "FIREFLY_SMTP_USER='${FIREFLY_SMTP_USER}'"
        "FIREFLY_SMTP_PASS='${FIREFLY_SMTP_PASS}'"
        "FIREFLY_SMTP_FROM=${FIREFLY_SMTP_FROM}"
    )

    echo ""
    echo "The following environment configuration will be saved:"
    echo "-----------------------------------------------------"
    for line in "${CONFIG_LINES[@]}"; do
        echo "$line"
    done
    echo "-----------------------------------------------------"
    echo ""

    read -p "Proceed with this configuration? (y/n): " CONFIRM
    echo ""
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Configuration aborted by user."
        echo ""
        exit 1
    fi

    printf "%s\n" "${CONFIG_LINES[@]}" > "$ENV_FILE"
    echo ".env file saved to $ENV_FILE"
    echo ""
}

# Set up containers and initialize

setup_containers() {
    echo "Stopping all containers and removing volumes..."
    docker compose down -v || true

    if [ -d "$VOL_DIR" ]; then
        echo "The 'vol' directory exists:"
        echo " - In case of a new install type 'y' to clear its contents. WARNING! This will remove all previous configuration files and stored data."
        echo " - In case of an upgrade/installing a new application type 'n' (or press Enter)."
        read -p "Clear it now? (y/N): " CONFIRM
        echo ""
        if [[ "$CONFIRM" == "y" ]]; then
            echo "Clearing 'vol' directory..."
            rm -rf "${VOL_DIR:?}"/*
        fi
    fi

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 20 seconds for services to initialize..."
    sleep 20

    echo "Done! Firefly III should be available at: https://${FIREFLY_APP_HOSTNAME}"
    echo ""
}

# -------------------
# Main
# -------------------
check_requirements

if [ -f "$ENV_FILE" ]; then
    echo ".env file found. Loading existing configuration."
    load_existing_env
else
    echo ".env file not found. Generating defaults."
    generate_defaults
fi

prompt_for_configuration
confirm_and_save_configuration
create_networks
create_backup_tasks
setup_containers
