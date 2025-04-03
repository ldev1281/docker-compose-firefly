# Contributing to Firefly III Docker Installer

Thanks for your interest in contributing!

## 🧱 Branching Strategy

- All work must be based on the `dev` branch.
- Submit your Pull Requests **from a feature branch** (e.g., `feature/env-generator`) into `dev`.
- The `main` branch is reserved for production-ready code and releases.

## 🛠 Development Setup

```bash
git clone https://github.com/jordimock/docker-compose-firefly
cd docker-compose-firefly
git checkout dev
```

## ✅ Pull Request Checklist

Before submitting a PR, please:

- Ensure your code runs without errors
- Keep your commits clean and descriptive
- Test the `.env` generation script if modified
- Confirm Docker Compose works as expected

## 📦 Code Style & Format

- Use bash best practices (e.g., quoting variables, checking exit codes)
- Write all comments and messages in **English**
- Use `.env` for config and avoid hardcoding values

---

For questions or ideas, open an Issue. Thank you!