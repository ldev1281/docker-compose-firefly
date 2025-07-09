# Firefly III Docker Compose Deployment (with Caddy Reverse Proxy)

This repository provides a production-ready Docker Compose configuration for deploying [Firefly III](https://firefly-iii.org) — a personal finance manager — with PostgreSQL as the database backend and Caddy as a reverse proxy. The setup includes automatic initialization, secure environment variable handling, and optional support for relaying email through a SOCKS5h-aware SMTP proxy container.

## Setup Instructions

### 1. Clone the Repository

Clone the project to your server in the `/docker/firefly/` directory:

```bash
mkdir -p /docker/firefly
cd /docker/firefly

# Clone the main Firefly III project
git clone https://github.com/ldev1281/docker-compose-firefly.git .
```
## 2. Create Docker Network and Set Up Reverse Proxy

This project is designed to work with the reverse proxy configuration provided by [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). To enable this integration, follow these steps:

1. **Create the shared Docker network** (if it doesn't already exist):

   ```bash
   docker network create --driver bridge caddy-firefly
   ```
2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). repository.
   Once Caddy is installed, it will automatically detect the Firefly III container via the caddy-firefly network and route traffic accordingly.

## 3. Configure and Start the Application

Configuration Variables:

| Variable Name                          | Description                                                    | Default Value                            |
|----------------------------------------|----------------------------------------------------------------|------------------------------------------|
| FIREFLY_APP_HOSTNAME                   | Public domain name for Firefly III                             | firefly.example.com                      |
| FIREFLY_VERSION                        | Docker image tag for Firefly III                               | version-6.2.18                           |
| FIREFLY_POSTGRES_VERSION               | Docker image tag for PostgreSQL                                | 15                                       |
| FIREFLY_POSTGRES_USER                  | PostgreSQL username                                            | firefly                                  |
| FIREFLY_POSTGRES_PASSWORD              | PostgreSQL password                                            | (auto-generated or input manually)       |
| FIREFLY_POSTGRES_DB                    | PostgreSQL database name                                       | firefly                                  |
| FIREFLY_APP_KEY                        | Laravel application secret key                                 | (auto-generated)                         |
| FIREFLY_SMTP_USER                      | SMTP username for sending email notifications                  | postmaster@sandbox123.mailgun.org        |
| FIREFLY_SMTP_PASS                      | SMTP password                                                  | password                                 |
| FIREFLY_SMTP_FROM                      | SMTP sender address                                            | firefly@sandbox123.mailgun.org           |
| FIREFLY_SMTP_FROM_NAME                 | SMTP sender name                                               | Firefly                                  |
| FIREFLY_SOCAT_SMTP_HOST                | Target SMTP host (for socat container)                         | smtp.mailgun.org                         |
| FIREFLY_SOCAT_SMTP_PORT                | SMTP target and proxy listen port                              | 587                                      |
| FIREFLY_SOCAT_SMTP_SOCKS5H_HOST        | SOCKS5h proxy host (optional)                                  | (empty)                                  |
| FIREFLY_SOCAT_SMTP_SOCKS5H_PORT        | SOCKS5h proxy port (optional)                                  | (empty)                                  |
| FIREFLY_SOCAT_SMTP_SOCKS5H_USER        | SOCKS5h proxy username (optional)                              | (empty)                                  |
| FIREFLY_SOCAT_SMTP_SOCKS5H_PASSWORD    | SOCKS5h proxy password (optional)                              | (empty)                                  |

To configure and launch all required services, run the provided script:

    ./tools/init.bash

The script will:

- Prompt you to enter configuration values (press Enter to accept defaults).
- Generate secure random secrets automatically.
- Save all settings to the `.env` file located at the project root.
- Stop and reinitialize containers with clean volumes.

**Important:**  
Make sure to securely store your `.env` file locally for future reference or redeployment.


### 4. Start the Firefly Service

```
docker compose up -d
```

This will start Firefly and make your configured domains available.

### 5. Verify Running Containers

```
docker compose ps
```

You should see the `firefly-app` container running.

### 6. Persistent Data Storage

Firefly III stores important runtime data, uploaded files, and PostgreSQL database data using Docker volumes.

- `./vol/firefly-postgres` – PostgreSQL database volume
- `./vol/firefly-app` – Firefly III uploads and runtime storage

---

### Example Directory Structure

```
/docker/firefly/
├── docker-compose.yml
├── tools/
│ └── init.bash
├── vol/
│ ├── firefly-app/
│ └── firefly-postgres/ 
├── .env 
```


## Creating a Backup Task for Firefly

To create a backup task for your Firefly deployment using [`backup-tool`](https://github.com/jordimock/backup-tool), add a new task file to `/etc/limbo-backup/rsync.conf.d/`:

```bash
sudo nano /etc/limbo-backup/rsync.conf.d/10-firefly.conf.bash
```

Paste the following contents:

```bash
CMD_BEFORE_BACKUP="docker compose --project-directory /docker/firefly down"
CMD_AFTER_BACKUP="docker compose --project-directory /docker/firefly up -d"

INCLUDE_PATHS=(
  "/docker/firefly/.env"
  "/docker/firefly/vol"
)
```
## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.
