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
   docker network create --driver bridge --internal proxy-client-firefly
   ```
2. **Set up the Caddy reverse proxy** by following the instructions in the [`docker-compose-caddy`](https://github.com/ldev1281/docker-compose-caddy). repository.
   Once Caddy is installed, it will automatically detect the Firefly III container via the caddy-firefly network and route traffic accordingly.

## 3. Configure and Start the Application

Configuration Variables:

| Variable                         | Description                                | Example / Default                          |
|----------------------------------|--------------------------------------------|--------------------------------------------|
| `FIREFLY_APP_HOSTNAME`           | Public domain for Firefly III              | `firefly.example.com`                      |
| `FIREFLY_VERSION`                | Firefly Docker image tag                   | `version-6.2.18`                           |
| `FIREFLY_POSTGRES_VERSION`       | PostgreSQL image version                   | `15`                                       |
| `FIREFLY_POSTGRES_USER`          | PostgreSQL username                        | `firefly`                                  |
| `FIREFLY_POSTGRES_PASSWORD`      | PostgreSQL password                        | *(generated or input)*                     |
| `FIREFLY_POSTGRES_DB`            | Database name                              | `firefly`                                  |
| `FIREFLY_APP_KEY`                | Laravel app key                            | *(generated)*                              |
| `FIREFLY_SMTP_HOST`              | SMTP host                                  | `smtp.mailgun.org`                         |
| `FIREFLY_SMTP_PORT`              | SMTP port                                  | `587`                                      |
| `FIREFLY_SMTP_USER`              | SMTP username                              | `postmaster@sandbox123.mailgun.org`        |
| `FIREFLY_SMTP_PASS`              | SMTP password                              | `password`                                 |
| `FIREFLY_SMTP_FROM`              | Sender email address                       | `firefly@sandbox123.mailgun.org`           |

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

CMD_BEFORE_RESTORE="docker compose --project-directory /docker/firefly down || true"
CMD_AFTER_RESTORE=(
"docker network create --driver bridge --internal proxy-client-firefly || true"
"docker compose --project-directory /docker/firefly up -d"
)

INCLUDE_PATHS=(
  "/docker/firefly"
)
```
## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.
