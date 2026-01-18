# Developer Documentation

## Table of Contents

1. [Project Architecture](#project-architecture)
2. [Prerequisites](#prerequisites)
3. [Environment Setup from Scratch](#environment-setup-from-scratch)
4. [Project Structure](#project-structure)
5. [Docker Services](#docker-services)
6. [Docker Compose Configuration](#docker-compose-configuration)
7. [Build Process](#build-process)
8. [Container Management](#container-management)
9. [Volume Management](#volume-management)
10. [Networking](#networking)
11. [Development Workflow](#development-workflow)
12. [Debugging Guide](#debugging-guide)

---

## Project Architecture

### Overview

This project implements a WordPress infrastructure using Docker containers. The architecture follows a microservices pattern with three isolated services communicating through a private Docker network.

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST MACHINE                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              DOCKER ENGINE                                 │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │          Docker Network: inception (bridge)          │ │  │
│  │  │                                                       │ │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │ │  │
│  │  │  │   NGINX     │  │  WORDPRESS  │  │  MARIADB    │  │ │  │
│  │  │  │             │  │             │  │             │  │ │  │
│  │  │  │ Port: 443   │←→│ Port: 9000  │←→│ Port: 3306  │  │ │  │
│  │  │  │ TLS 1.2/1.3 │  │  PHP-FPM    │  │   MySQL     │  │ │  │
│  │  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │ │  │
│  │  │         │                │                │          │ │  │
│  │  │         └────────────────┴────────────────┘          │ │  │
│  │  │                          │                            │ │  │
│  │  │                   Docker Secrets                      │ │  │
│  │  │                (tmpfs mounts at /run/secrets/)        │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │         │                      │                            │  │
│  │    [Volume]                [Volume]                        │  │
│  │  wordpress_data           mariadb_data                     │  │
│  │         │                      │                            │  │
│  └─────────┼──────────────────────┼────────────────────────────┘  │
│            ↓                      ↓                               │
│       ~/data/wordpress       ~/data/mariadb                       │
│       (bind mount)           (bind mount)                         │
└─────────────────────────────────────────────────────────────────┘
         ↑
    Browser → https://mmilliot.42.fr:443
```

### Service Responsibilities

| Service | Image Base | Purpose | Exposed Ports | Dependencies |
|---------|-----------|---------|---------------|--------------|
| **nginx** | debian:bookworm | HTTPS termination, reverse proxy | 443 (external) | wordpress (healthy) |
| **wordpress** | debian:bookworm | PHP-FPM, WordPress core | 9000 (internal) | mariadb (healthy) |
| **mariadb** | debian:bookworm | MySQL database | 3306 (internal) | None |

### Communication Flow

1. **Browser** → `https://mmilliot.42.fr:443`
2. **nginx** receives HTTPS request (TLS termination)
3. **nginx** proxies PHP requests → `wordpress:9000` (FastCGI)
4. **wordpress** (PHP-FPM) processes request
5. **wordpress** queries database → `mariadb:3306`
6. **mariadb** returns data
7. Response flows back: `mariadb` → `wordpress` → `nginx` → `browser`

---

## Prerequisites

### System Requirements

- **OS**: Linux (Debian/Ubuntu recommended) or macOS
- **RAM**: Minimum 2GB available
- **Disk**: 5GB free space
- **Processor**: x86_64 architecture

### Required Software

| Software | Minimum Version | Installation |
|----------|----------------|--------------|
| Docker | 20.10+ | `apt install docker.io` or Docker Desktop |
| Docker Compose | 2.0+ | Included in Docker Desktop |
| Make | GNU Make 4.0+ | `apt install make` |
| Git | 2.0+ | `apt install git` |

### Verify Installation

```bash
docker --version          # Should show 20.10+
docker compose version    # Should show 2.0+
make --version           # Should show GNU Make 4.0+
```

---

## Environment Setup from Scratch

### 1. Clone the Repository

```bash
git clone <repository_url>
cd Inception
```

### 2. Configure Environment Variables

Create `.env` from template:

```bash
cp srcs/.env.example srcs/.env
nano srcs/.env
```

Required variables in `srcs/.env`:

```bash
# Database
MYSQL_DATABASE=wordpress_db       # Database name
MYSQL_DB_USER=wp_user            # WordPress DB user

# WordPress
WP_URL=https://your_login.42.fr  # Your domain
WP_TITLE=Inception WordPress     # Site title
WP_ADMIN_USER=your_login         # Admin username (NOT "admin")
WP_ADMIN_EMAIL=admin@example.com # Admin email
WP_USER=user1                    # Additional user
WP_USER_EMAIL=user1@example.com  # User email
```

**Note**: Passwords are NOT in `.env` - they're in Docker secrets.

### 3. Create Docker Secrets

```bash
mkdir -p secrets

# Create secret files (use strong passwords!)
echo -n "your_root_password" > secrets/mysql_root_password.txt
echo -n "your_user_password" > secrets/mysql_user_password.txt
echo -n "your_admin_password" > secrets/wordpress_admin_password.txt
echo -n "your_user_password" > secrets/wordpress_user_password.txt

# Secure permissions
chmod 600 secrets/*.txt
```

**Important**: Use `echo -n` (no trailing newline) to avoid whitespace in passwords.

### 4. Verify Configuration

```bash
# Check .env exists and is ignored
ls -la srcs/.env
git check-ignore srcs/.env  # Should output: srcs/.env

# Check secrets exist and are ignored
ls -la secrets/
git check-ignore secrets/mysql_root_password.txt  # Should output path

# Verify no secrets in git
git ls-files | grep -E "(\.env|secrets/)"  # Should be empty
```

---

## Project Structure

```
Inception/
├── Makefile                           # Build automation
├── README.md                          # Project overview
├── USER_DOC.md                        # End-user documentation
├── DEV_DOC.md                         # This file
├── .gitignore                         # Git ignore rules
│
├── secrets/                           # Docker secrets (NOT committed)
│   ├── .secrets.example               # Instructions for creating secrets
│   ├── mysql_root_password.txt        # MariaDB root password
│   ├── mysql_user_password.txt        # MariaDB user password
│   ├── wordpress_admin_password.txt   # WordPress admin password
│   └── wordpress_user_password.txt    # WordPress user password
│
└── srcs/
    ├── .env                           # Environment variables (NOT committed)
    ├── .env.example                   # Template for .env
    ├── docker-compose.yml             # Service orchestration
    │
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile             # MariaDB image definition
        │   ├── conf/
        │   │   └── 99-custom.cnf      # MariaDB configuration
        │   └── tools/
        │       └── init.sh            # Database initialization script
        │
        ├── nginx/
        │   ├── Dockerfile             # Nginx image definition
        │   ├── conf/
        │   │   └── nginx.conf         # Nginx server configuration
        │   └── tools/
        │       └── entrypoint.sh      # SSL cert generation + nginx start
        │
        └── wordpress/
            ├── Dockerfile             # WordPress image definition
            ├── conf/
            │   └── www.conf           # PHP-FPM pool configuration
            └── tools/
                └── wp-cli.sh          # WordPress installation script
```

### File Purposes

| File | Purpose |
|------|---------|
| `Makefile` | Build automation, defines targets (all, build, run, clean, etc.) |
| `docker-compose.yml` | Defines services, networks, volumes, secrets orchestration |
| `Dockerfile` | Image build instructions for each service |
| `*.sh` | Initialization and entrypoint scripts |
| `*.conf` | Service-specific configuration files |
| `.env` | Non-sensitive environment variables |
| `secrets/*.txt` | Sensitive credentials (passwords, keys) |

---

## Docker Services

### MariaDB Service

**Dockerfile**: `srcs/requirements/mariadb/Dockerfile`

**Key Points**:
- Base: `debian:bookworm` (penultimate stable Debian)
- Package: `mariadb-server` (installed via apt)
- Config: Custom settings in `99-custom.cnf` (bind to 0.0.0.0, UTF8)
- Init: `init.sh` creates database, users, sets passwords from secrets
- Port: 3306 exposed only within Docker network

**Initialization Flow** (`init.sh`):
1. Read root password from `/run/secrets/mysql_root_password`
2. Start MariaDB temporarily in background
3. Set root password
4. Create database (`$MYSQL_DATABASE`)
5. Create user (`$MYSQL_DB_USER`) with password from secret
6. Grant privileges
7. Stop temporary server
8. Start MariaDB as PID 1 (`exec mariadbd`)

---

### WordPress Service

**Dockerfile**: `srcs/requirements/wordpress/Dockerfile`

**Key Points**:
- Base: `debian:bookworm`
- PHP: Version 8.2 with FPM (FastCGI Process Manager)
- WP-CLI: Official WordPress command-line tool
- Config: PHP-FPM listens on port 9000 (not socket)
- Init: `wp-cli.sh` downloads WordPress, creates config, installs

**Initialization Flow** (`wp-cli.sh`):
1. Read passwords from secrets
2. Wait for MariaDB to be ready (health check loop)
3. Download WordPress core (if not exists)
4. Create `wp-config.php` with database credentials
5. Install WordPress (admin user)
6. Create additional user (author role)
7. Start PHP-FPM as PID 1 (`exec php-fpm8.2 -F`)

---

### Nginx Service

**Dockerfile**: `srcs/requirements/nginx/Dockerfile`

**Key Points**:
- Base: `debian:bookworm`
- Nginx: Web server with TLS 1.2/1.3 support
- SSL: Self-signed certificate generated at runtime
- Config: FastCGI proxy to `wordpress:9000`
- Port: Only 443 exposed (HTTPS only)

**Nginx Configuration** (`nginx.conf`):
```nginx
server {
    listen 443 ssl;
    server_name mmilliot.42.fr;

    ssl_certificate /etc/nginx/ssl/mmilliot.crt;
    ssl_certificate_key /etc/nginx/ssl/mmilliot.key;
    ssl_protocols TLSv1.2 TLSv1.3;  # Only secure protocols

    root /var/www/html;
    index index.php;

    # Proxy PHP to WordPress container
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;  # Docker network resolution
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

---

## Docker Compose Configuration

**File**: `srcs/docker-compose.yml`

### Secrets Declaration

```yaml
secrets:
  mysql_root_password:
    file: ../secrets/mysql_root_password.txt
  mysql_user_password:
    file: ../secrets/mysql_user_password.txt
  wordpress_admin_password:
    file: ../secrets/wordpress_admin_password.txt
  wordpress_user_password:
    file: ../secrets/wordpress_user_password.txt
```

**How it works**:
- Secrets are mounted as read-only files in `/run/secrets/<secret_name>`
- Files are stored in tmpfs (RAM only, never written to disk inside container)
- Not visible in `docker inspect` output
- Permissions: 400 (read-only for owner)

### Service Dependencies

```yaml
services:
  mariadb:
    # No dependencies - starts first

  wordpress:
    depends_on:
      mariadb:
        condition: service_healthy  # Waits for mariadb healthcheck

  nginx:
    depends_on:
      wordpress:
        condition: service_healthy  # Waits for wordpress healthcheck
```

**Startup order**:
1. MariaDB starts → healthcheck passes
2. WordPress starts (after mariadb healthy) → healthcheck passes
3. Nginx starts (after wordpress healthy)

### Healthchecks

```yaml
mariadb:
  healthcheck:
    test: ["CMD-SHELL", "mariadb -uroot -p$(cat /run/secrets/mysql_root_password) -e 'SELECT 1' || exit 1"]
    interval: 10s      # Check every 10 seconds
    timeout: 5s        # Fail if takes >5s
    retries: 5         # Try 5 times before marking unhealthy
    start_period: 30s  # Grace period before first check

wordpress:
  healthcheck:
    test: ["CMD-SHELL", "test -f /var/www/html/wp-config.php && pgrep php-fpm"]
    # Checks: wp-config exists AND php-fpm is running

nginx:
  healthcheck:
    test: ["CMD", "curl", "-f", "-k", "https://localhost:443"]
    # Checks: nginx responds to HTTPS on 443
```

### Networks

```yaml
networks:
  inception:
    driver: bridge  # Default bridge network
```

**How it works**:
- All containers attached to `inception` network
- Containers can resolve each other by service name (DNS)
- Example: `wordpress` container can reach `mariadb:3306`
- Isolated from host network (only port 443 exposed)

### Volumes

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/data/mariadb  # Bind mount to host

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/data/wordpress
```

**Why `driver_opts` with `type: none` and `o: bind`?**

This creates a "named volume" that's actually a bind mount to a specific host path. It's a hybrid approach:
- Named volume syntax (portable in docker-compose.yml)
- Bind mount behavior (data at predictable host location)
- Required by subject: data must be in `~/data/` (or `/home/user/data/`)

**Alternative** (pure named volume):
```yaml
volumes:
  mariadb_data:
    driver: local  # Docker manages location
```
This would store data in `/var/lib/docker/volumes/` - not allowed by subject.

---

## Build Process

### Build Command

```bash
make build
# Executes: docker compose -f srcs/docker-compose.yml build
```

### Build Phases

1. **Read docker-compose.yml**
   - Parse service definitions
   - Identify Dockerfiles to build

2. **Build each service** (in parallel by default)

3. **Execute Dockerfile instructions**:
   - `FROM`: Pull base image (`debian:bookworm`)
   - `RUN`: Execute commands (apt install, etc.)
   - `COPY`: Copy files from build context
   - `EXPOSE`: Document ports (metadata only)
   - `CMD`: Set default command

4. **Tag images**:
   ```
   inception-mariadb:latest
   inception-wordpress:latest
   inception-nginx:latest
   ```

### Build Options

```bash
# Force rebuild (ignore cache)
docker compose -f srcs/docker-compose.yml build --no-cache

# Verbose output
docker compose -f srcs/docker-compose.yml build --progress=plain

# Build specific service
docker compose -f srcs/docker-compose.yml build mariadb
```

---

## Container Management

### Start Containers

```bash
make run
# Executes: docker compose -f srcs/docker-compose.yml up -d
```

**What happens**:
1. Create `inception` network (if not exists)
2. Mount volumes
3. Inject secrets as tmpfs mounts
4. Start containers in dependency order
5. Detach (`-d` flag)

### View Running Containers

```bash
docker ps
# Shows: container ID, image, status, ports, names
```

Expected output:
```
CONTAINER ID   IMAGE                  STATUS                    PORTS
abc123         inception-nginx        Up 2 minutes (healthy)    0.0.0.0:443->443/tcp
def456         inception-wordpress    Up 3 minutes (healthy)    9000/tcp
ghi789         inception-mariadb      Up 4 minutes (healthy)    3306/tcp
```

### Stop Containers

```bash
make down
# Executes: docker compose -f srcs/docker-compose.yml down
```

Stops and removes containers, but keeps:
- Volumes (data preserved)
- Images (no rebuild needed)
- Network (recreated on next up)

### Execute Commands in Containers

```bash
# Open bash shell
docker exec -it mariadb bash

# Run single command
docker exec mariadb ls /var/lib/mysql

# Check secrets are mounted
docker exec mariadb ls -la /run/secrets/

# Connect to database
docker exec -it mariadb mariadb -uroot -p
```

---

## Volume Management

### Volume Locations

```bash
# On host machine
~/data/mariadb/       # MariaDB database files
~/data/wordpress/     # WordPress installation

# Inside containers
/var/lib/mysql        # mariadb container
/var/www/html         # wordpress & nginx containers
```

### Inspect Volumes

```bash
# List all volumes
docker volume ls

# Inspect volume details
docker volume inspect inception_mariadb_data

# View volume contents (from host)
ls -la ~/data/mariadb/
ls -la ~/data/wordpress/
```

### Volume Persistence

Data survives:
- ✅ Container stop (`make down`)
- ✅ Container removal
- ✅ Image rebuild
- ❌ `make fclean` (explicitly deletes volumes)

### Backup Volumes

```bash
# Backup MariaDB
docker exec mariadb mariadb-dump -uroot -p --all-databases > backup.sql

# Backup WordPress files
tar -czf wordpress-backup.tar.gz ~/data/wordpress/
```

---

## Networking

### Network Configuration

```bash
# Inspect network
docker network inspect inception

# Output shows:
# - Subnet: 172.x.0.0/16
# - Gateway: 172.x.0.1
# - Connected containers with IPs
```

### DNS Resolution

Containers resolve each other by service name:

```bash
# From wordpress container
docker exec wordpress ping mariadb
# Resolves to mariadb container IP (e.g., 172.18.0.2)

# From nginx container
docker exec nginx ping wordpress
# Resolves to wordpress container IP (e.g., 172.18.0.3)
```

### Port Mapping

Only nginx exposes port to host:

```yaml
nginx:
  ports:
    - "443:443"  # Host:Container
```

Other services use internal ports only:
- `mariadb:3306` - accessible only within `inception` network
- `wordpress:9000` - accessible only within `inception` network

### Network Isolation

```bash
# This WORKS (inside network)
docker exec nginx curl wordpress:9000

# This FAILS (from host, port not exposed)
curl localhost:9000
```

---

## Development Workflow

### Making Changes

1. **Modify files** (Dockerfile, configs, scripts)

2. **Rebuild affected service**:
   ```bash
   docker compose -f srcs/docker-compose.yml build <service>
   ```

3. **Restart service**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --force-recreate <service>
   ```

4. **Test changes**:
   ```bash
   docker logs <service>
   ```

### Quick Rebuild

```bash
# Full rebuild
make re
# Equivalent to: make fclean && make

# Rebuild single service
docker compose -f srcs/docker-compose.yml up -d --build mariadb
```

### Live Debugging

```bash
# Watch logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs -f mariadb

# Last 50 lines
docker logs --tail 50 wordpress
```

---

## Debugging Guide

### Common Issues

#### 1. Container Won't Start

```bash
# Check logs
docker logs <container>

# Check exit code
docker ps -a | grep <container>

# Inspect container config
docker inspect <container>
```

#### 2. Service Unhealthy

```bash
# View healthcheck logs
docker inspect <container> | grep -A 10 Health

# Manually run healthcheck command
docker exec <container> <healthcheck_command>
```

#### 3. Network Issues

```bash
# Verify network exists
docker network ls | grep inception

# Check container connectivity
docker exec nginx ping mariadb
docker exec wordpress ping mariadb

# Inspect network
docker network inspect inception
```

#### 4. Volume Issues

```bash
# Verify mount points
docker inspect <container> | grep -A 5 Mounts

# Check host directory permissions
ls -la ~/data/

# Check contents from inside container
docker exec <container> ls -la /var/www/html
```

#### 5. Secrets Not Loading

```bash
# Verify secrets exist on host
ls -la secrets/

# Check secrets mounted in container
docker exec <container> ls -la /run/secrets/

# Read secret value (debug only!)
docker exec <container> cat /run/secrets/mysql_root_password
```

### Debug Mode

Enable verbose logging:

```bash
# Build with verbose output
docker compose -f srcs/docker-compose.yml build --progress=plain

# Run without detach (see real-time output)
docker compose -f srcs/docker-compose.yml up
```

### Shell Access

```bash
# MariaDB
docker exec -it mariadb bash

# WordPress
docker exec -it wordpress bash

# Nginx
docker exec -it nginx bash
```

### Database Access

```bash
# Connect to MySQL
docker exec -it mariadb mariadb -uroot -p

# List databases
docker exec mariadb mariadb -uroot -p -e "SHOW DATABASES;"

# Check WordPress tables
docker exec mariadb mariadb -uroot -p wordpress_db -e "SHOW TABLES;"
```

---

## Performance Optimization

### Build Cache

Docker caches layers. Optimize Dockerfile order:

```dockerfile
# GOOD: Dependencies change rarely, cached
RUN apt-get update && apt-get install -y nginx
COPY conf/nginx.conf /etc/nginx/

# BAD: Config changes often, invalidates cache
COPY conf/nginx.conf /etc/nginx/
RUN apt-get update && apt-get install -y nginx
```

### Container Resources

Monitor resource usage:

```bash
# Real-time stats
docker stats

# Specific container
docker stats mariadb
```

### Image Size

Check image sizes:

```bash
docker images | grep inception
```

Reduce size:
- Use `--no-install-recommends` with apt
- Clean apt cache: `rm -rf /var/lib/apt/lists/*`
- Multi-stage builds (advanced)

---

## Security Considerations

### Secrets Management

✅ **DO**:
- Use Docker secrets for passwords
- Store secrets in tmpfs (RAM only)
- Never commit secrets to git
- Use `.gitignore` for `secrets/` directory

❌ **DON'T**:
- Put passwords in environment variables
- Hardcode credentials in Dockerfiles
- Use same password for all services
- Commit `.env` file

### Network Security

- Only port 443 exposed to host
- All inter-service communication over private network
- TLS 1.2/1.3 only (no SSLv3, TLS 1.0/1.1)

### Container Isolation

- Containers run as non-root where possible
- Read-only filesystems for secrets
- No `--privileged` flag used

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [WordPress Codex](https://codex.wordpress.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

---

**Last Updated**: 2026-01-18
**Maintainer**: mmilliot
