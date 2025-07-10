# -------------------------------------
# Firefly III setup script
# -------------------------------------

# Get the absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

VOL_DIR="${SCRIPT_DIR}/../vol/"

FIREFLY_POSTGRES_VERSION=15
FIREFLY_VERSION=version-6.2.18

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

    read -p "FIREFLY_SOCAT_SMTP_PORT [${FIREFLY_SOCAT_SMTP_PORT:-587}]: " input
    FIREFLY_SOCAT_SMTP_PORT=${input:-${FIREFLY_SOCAT_SMTP_PORT:-587}}

    read -p "FIREFLY_SOCAT_SMTP_HOST [${FIREFLY_SOCAT_SMTP_HOST:-smtp.mailgun.org}]: " input
    FIREFLY_SOCAT_SMTP_HOST=${input:-${FIREFLY_SOCAT_SMTP_HOST:-smtp.mailgun.org}}

    read -p "FIREFLY_SMTP_USER [${FIREFLY_SMTP_USER:-postmaster@sandbox123.mailgun.org}]: " input
    FIREFLY_SMTP_USER=${input:-${FIREFLY_SMTP_USER:-postmaster@sandbox123.mailgun.org}}

    read -p "FIREFLY_SMTP_PASS [${FIREFLY_SMTP_PASS:-password}]: " input
    FIREFLY_SMTP_PASS=${input:-${FIREFLY_SMTP_PASS:-password}}

    read -p "FIREFLY_SMTP_FROM [${FIREFLY_SMTP_FROM:-firefly@sandbox123.mailgun.org}]: " input
    FIREFLY_SMTP_FROM=${input:-${FIREFLY_SMTP_FROM:-firefly@sandbox123.mailgun.org}}

    read -p "FIREFLY_SMTP_FROM_NAME [${FIREFLY_SMTP_FROM_NAME:-Firefly}]: " input
    FIREFLY_SMTP_FROM_NAME=${input:-${FIREFLY_SMTP_FROM_NAME:-Firefly}}

    read -p "FIREFLY_SOCAT_SMTP_SOCKS5H_HOST [${FIREFLY_SOCAT_SMTP_SOCKS5H_HOST:-}]: " input
    FIREFLY_SOCAT_SMTP_SOCKS5H_HOST=${input:-${FIREFLY_SOCAT_SMTP_SOCKS5H_HOST:-}}

    read -p "FIREFLY_SOCAT_SMTP_SOCKS5H_PORT [${FIREFLY_SOCAT_SMTP_SOCKS5H_PORT:-}]: " input
    FIREFLY_SOCAT_SMTP_SOCKS5H_PORT=${input:-${FIREFLY_SOCAT_SMTP_SOCKS5H_PORT:-}}

    read -p "FIREFLY_SOCAT_SMTP_SOCKS5H_USER [${FIREFLY_SOCAT_SMTP_SOCKS5H_USER:-}]: " input
    FIREFLY_SOCAT_SMTP_SOCKS5H_USER=${input:-${FIREFLY_SOCAT_SMTP_SOCKS5H_USER:-}}

    read -p "FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD [${FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD:-}]: " input
    FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD=${input:-${FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD:-}}
}
# Display configuration and ask user to confirm
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
        "# SMTP Firefly"
        "FIREFLY_SMTP_USER=${FIREFLY_SMTP_USER}"
        "FIREFLY_SMTP_PASS=${FIREFLY_SMTP_PASS}"
        "FIREFLY_SMTP_FROM=${FIREFLY_SMTP_FROM}"
        "FIREFLY_SMTP_FROM_NAME=${FIREFLY_SMTP_FROM_NAME}"
        ""
        "# SMTP socat proxy settings"
        "FIREFLY_SOCAT_SMTP_PORT=${FIREFLY_SOCAT_SMTP_PORT}"
        "FIREFLY_SOCAT_SMTP_HOST=${FIREFLY_SOCAT_SMTP_HOST}"
        "FIREFLY_SOCAT_SMTP_SOCKS5H_HOST=${FIREFLY_SOCAT_SMTP_SOCKS5H_HOST}"
        "FIREFLY_SOCAT_SMTP_SOCKS5H_PORT=${FIREFLY_SOCAT_SMTP_SOCKS5H_PORT}"
        "FIREFLY_SOCAT_SMTP_SOCKS5H_USER=${FIREFLY_SOCAT_SMTP_SOCKS5H_USER}"
        "FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD=${FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD}"
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

    echo "Clearing volume data..."
    [ -d "${VOL_DIR}" ] && rm -rf "${VOL_DIR}"/*

    echo "Starting containers..."
    docker compose up -d

    echo "Waiting 60 seconds for services to initialize..."
    sleep 60

    echo "Done! Firefly III should be available at: $FIREFLY_APP_HOSTNAME"
    echo ""
}

# -----------------------------------
# Main logic
# -----------------------------------

if [ -f "$ENV_FILE" ]; then
    echo ".env file found. Loading existing configuration."
    load_existing_env
else
    echo ".env file not found. Generating defaults."
    generate_defaults
fi

prompt_for_configuration
confirm_and_save_configuration
setup_containers
