# Firefly III Docker Installer

Automated installer for Firefly III on a Debian server. Deploys everything under `/docker/firefly` using Docker Compose.

## 🔧 What it installs

- Firefly III (personal finance manager)
- PostgreSQL (database)
- Firefly Importer (optional)

> ⚠️ Caddy is **already installed** on the host and acts as a reverse proxy. This script does **not** install Caddy.

## 🧱 Requirements

- Debian 12 (minimal system)
- Root access
- Directory `/docker/firefly`
- Caddy reverse proxy already installed and running

## 📁 Project Structure

```
/docker/firefly
├── docker-compose.yml
├── .env                # Auto-generated during install
├── init.bash  # Main installer script
└── vol/                # Container data
```

## 🚀 Quick Start

1. SSH into your server as root.
2. Clone this repository:

```bash
git clone https://github.com/jordimock/docker-compose-firefly /docker/firefly
cd /docker/firefly
```

3. Create a shared Docker network for Caddy and Firefly III:

```bash
docker network create --driver bridge caddy-firefly
```

> This network is required for Firefly III to communicate with Caddy reverse proxy.

4. Start the installer:

```bash
bash install-firefly.sh
```

> The script will prompt you for required values (domain, database password, admin email, etc.), and automatically generate the `.env` file.

## 🌐 Caddy Configuration

Ensure Caddy is set to proxy requests to Firefly III, which runs on `localhost:8080` inside Docker.

Example `Caddyfile` entry:

```
firefly.example.com {
    reverse_proxy localhost:8080
}
```

## 📎 Useful Links

- [Firefly III Docs](https://docs.firefly-iii.org)
- [Firefly III Importer](https://docs.firefly-iii.org/references/faq/data-importer/general/)

## 🤝 Contributing

Pull requests are welcome. Please review the `CONTRIBUTING.md` guide before submitting.

## 📄 License

MIT License.

