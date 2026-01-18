_This project has been created as part of the 42 curriculum by mmilliot._

---

# Inception

A Docker-based system administration project that containerizes a complete WordPress infrastructure with NGINX, PHP-FPM, and MariaDB.

---

## Description

Inception demonstrates system administration and containerization skills by deploying a functional WordPress website using Docker. The project implements a three-tier architecture:

- **NGINX**: Reverse proxy with HTTPS (TLS 1.2/1.3) termination
- **WordPress**: Content Management System with PHP-FPM
- **MariaDB**: Database server

Each service runs in an isolated Docker container, communicating through a private network. The infrastructure uses Docker secrets for secure credential management and named volumes for data persistence.

**Key Features**:
- Custom Dockerfiles (no pre-built images)
- HTTPS-only access with SSL/TLS
- Docker secrets for password management
- Automated deployment with Makefile
- Health checks and service dependencies

---

## Instructions

### Quick Start

```bash
# 1. Clone and configure
git clone <repository>
cd Inception
cp srcs/.env.example srcs/.env
nano srcs/.env  # Edit your configuration

# 2. Create secrets
mkdir -p secrets
echo -n "your_password" > secrets/mysql_root_password.txt
echo -n "your_password" > secrets/mysql_user_password.txt
echo -n "your_password" > secrets/wordpress_admin_password.txt
echo -n "your_password" > secrets/wordpress_user_password.txt

# 3. Launch
make

# 4. Access
# Open https://mmilliot.42.fr in your browser
```

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Make 4.0+
- 2GB RAM, 5GB disk

### Main Commands

```bash
make        # Build and start everything
make down   # Stop containers (keep data)
make fclean # Complete cleanup (removes data)
make re     # Rebuild everything
```

**For detailed instructions, see [USER_DOC.md](USER_DOC.md)**

---

## Resources

### Documentation
- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [NGINX Docs](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)

### AI Usage

Claude AI (Anthropic) was used as a **personal tutor and learning guide** throughout this project:

- **Teaching**: Explaining Docker concepts (containers, networks, volumes, secrets), Docker Compose orchestration, TLS/SSL, FastCGI, PHP-FPM
- **Code Review**: Analyzing configuration errors, suggesting fixes, explaining security best practices
- **Debugging**: Helping diagnose issues (volume paths macOS/Linux, healthchecks, git history cleanup)
- **Documentation**: Structuring README, USER_DOC, DEV_DOC according to requirements

**Approach**: Every piece of code was written and understood by the student. The AI explained the "why" behind each choice, not providing copy-paste solutions. All implementations were validated through testing.

---

## Project Description

### Architecture Overview

This project uses Docker to create an isolated, reproducible infrastructure:

```
Browser (HTTPS:443)
    ↓
[NGINX Container] ← TLS termination, reverse proxy
    ↓
[WordPress Container] ← PHP-FPM application
    ↓
[MariaDB Container] ← Database
    ↓
Volumes (~/data/) ← Persistent storage
```

**Design Principles**:
- **Isolation**: Each service in its own container
- **Security**: HTTPS-only, Docker secrets, private network
- **Persistence**: Named volumes for data storage
- **Automation**: Makefile for deployment

**For detailed architecture, see [DEV_DOC.md](DEV_DOC.md)**

---

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | VMs | Docker |
|--------|-----|--------|
| Isolation | Hardware-level | Process-level |
| Resources | Heavy (full OS) | Lightweight (shared kernel) |
| Startup | Minutes | Seconds |
| Size | Gigabytes | Megabytes |
| Use Case | OS isolation | Application isolation |

**Why Docker?** Faster iteration, smaller footprint, easier version control, industry standard for microservices.

#### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|--------|----------------------|----------------|
| Storage | Process environment | Mounted file (`/run/secrets/`) |
| Visibility | Visible in `docker inspect` | Hidden |
| Security | Moderate (can leak in logs) | High (tmpfs, read-only) |
| Persistence | In memory | RAM only (tmpfs) |

**Implementation**: Passwords use Docker secrets (secure), configuration uses env vars (convenient).

#### Docker Network vs Host Network

| Aspect | Bridge Network | Host Network |
|--------|---------------|--------------|
| Isolation | Network isolated | Shares host stack |
| DNS | Container name resolution | Manual IP management |
| Security | Protected | Direct exposure |
| Port Conflicts | None (internal ports) | Can conflict |

**Why bridge?** Security (isolation), DNS (name resolution), flexibility (only port 443 exposed).

#### Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|--------------|-------------|
| Management | Docker-managed | User-specified path |
| Location | `/var/lib/docker/volumes/` | Any directory |
| Portability | Portable | Host-dependent |
| Backup | Docker commands | Direct filesystem |

**Implementation**: Hybrid approach (named volume with bind mount behavior):
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/data/mariadb
```

This satisfies project requirements (data in `~/data/`) while using named volume syntax.

---

## License

Part of the 42 school curriculum. Subject to academic policies.

---

## Contact

**Author**: mmilliot
**Project**: Inception
**Year**: 2026
