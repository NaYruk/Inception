# User Documentation

## Available Services

- WordPress (PHP-FPM)
- Nginx (Web server with HTTPS)
- MariaDB (Database)

---

## Getting Started

### Prerequisites

Before starting, you must configure secrets and the .env file:

1. Read and follow instructions in `./secrets/.secrets.example`
2. Read and follow instructions in `./srcs/.env.example`

### Launch the Project

Once secrets and .env are configured, run:

```bash
make
```

Wait until all services are **"Healthy"**. This takes approximately 30-60 seconds.

### Access the Website

Open your browser and navigate to:

```
https://your_login.42.fr
```

**Note**: Replace `your_login` with the value of `WP_URL` from your `.env` file (e.g., `mmilliot.42.fr`).

You will see a security warning because the SSL certificate is self-signed. Click "Advanced" → "Proceed to site". This is normal for local development.

Well done! You are now on the WordPress website.

---

## Connecting as User or Administrator

### Access Admin Panel

In your browser, navigate to:

```
https://your_login.42.fr/wp-admin
```

**Login credentials:**
- **Username**: Value from `WP_ADMIN_USER` in your `.env` file
- **Password**: Content of `secrets/wordpress_admin_password.txt`

### Access as Regular User

You can also login with the second user:
- **Username**: Value from `WP_USER` in your `.env` file
- **Password**: Content of `secrets/wordpress_user_password.txt`

This user has "Author" role (can create and edit posts but cannot manage the site).

---

## Managing Credentials

All passwords are stored as files in the `secrets/` directory:

| Credential | File Location | Description |
|------------|---------------|-------------|
| MySQL root password | `secrets/mysql_root_password.txt` | Database root user |
| MySQL user password | `secrets/mysql_user_password.txt` | WordPress database connection |
| WordPress admin password | `secrets/wordpress_admin_password.txt` | Admin panel login |
| WordPress user password | `secrets/wordpress_user_password.txt` | Regular user login |

**To change a password:**
1. Edit the corresponding file in `secrets/`
2. Restart the project: `make re`

**Security**: Never commit these files to git! They are ignored by `.gitignore`.

---

## Checking Service Status

### Verify containers are running

```bash
docker ps
```

You should see 3 containers with status "Up (healthy)":
- `nginx`
- `wordpress`
- `mariadb`

### View logs

```bash
# All services (live stream)
make logs

# Specific service
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Test website connectivity

```bash
curl -k https://mmilliot.42.fr
```

Should return HTML content if everything is working correctly.

---

## Stopping the Project

### Complete cleanup (removes all data)

```bash
make fclean
```

**Warning**: This command:
- Stops and removes all containers
- Deletes all volumes and images
- Removes all data from `~/data/`
- This action is **irreversible**!

### Stop containers but keep data

```bash
make down
```

This stops containers but preserves your data in `~/data/`.

---

## Restarting the Project

### Full rebuild (clean + restart)

```bash
make re
```

This runs `make fclean` followed by `make` (complete cleanup and restart).

### Restart without rebuilding

```bash
make down
make run
```

This restarts existing containers without rebuilding images.

---

## Troubleshooting

### Service not starting

Check logs for error messages:

```bash
docker logs <service_name>
```

Common issues:
- Port 443 already in use
- Missing secrets files
- Incorrect permissions on secrets files

### Cannot access website

1. **Verify `/etc/hosts` configuration:**

```bash
cat /etc/hosts | grep mmilliot.42.fr
```

Should display: `127.0.0.1   mmilliot.42.fr`

2. **Check if containers are running:**

```bash
docker ps
```

All 3 containers should be listed with "Up" status.

3. **Verify nginx is responding:**

```bash
curl -k https://localhost:443
```

### Database connection errors

1. **Verify MariaDB is healthy:**

```bash
docker ps | grep mariadb
```

2. **Check MariaDB logs:**

```bash
docker logs mariadb
```

3. **Verify secrets are accessible:**

```bash
docker exec mariadb cat /run/secrets/mysql_root_password
```

Should display the password without errors.

---

## Data Persistence

All website data is stored in:

```
~/data/mariadb/      # Database files
~/data/wordpress/    # WordPress files (themes, plugins, uploads)
```

Even after stopping or removing containers, your data remains in these directories unless you run `make fclean`.

---

## Support

For additional help:
- Review container logs: `docker logs <container_name>`
- Check configuration: `cat srcs/.env`
- Verify Docker status: `docker ps -a`
- Inspect volumes: `ls -la ~/data/`
