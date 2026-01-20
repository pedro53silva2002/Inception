# Inception - User Documentation

This guide explains how to use and manage the Inception WordPress infrastructure.

---

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing the Website](#accessing-the-website)
4. [Managing Credentials](#managing-credentials)
5. [Checking Service Status](#checking-service-status)

---

## Services Overview

Inception provides a complete web hosting stack with three interconnected services:

| Service | Purpose | What It Does |
|---------|---------|--------------|
| **Nginx** | Web Server | Handles HTTPS requests, serves static files, and forwards PHP requests to WordPress |
| **WordPress** | Website Application | Runs the WordPress CMS using PHP-FPM to process dynamic content |
| **MariaDB** | Database | Stores all WordPress data (posts, users, settings, etc.) |

### How They Work Together

```
User Browser → Nginx (HTTPS:443) → WordPress (PHP-FPM:9000) → MariaDB (3306)
```

1. Your browser connects to **Nginx** over HTTPS (port 443)
2. Nginx serves static files directly or forwards PHP requests to **WordPress**
3. WordPress processes the request and queries **MariaDB** for data
4. The response travels back through the same path to your browser

---

## Starting and Stopping the Project

### Prerequisites

Before starting, ensure you have:
- Docker and Docker Compose installed
- Data directories created: `mkdir -p ~/data/database ~/data/wordpress_files`
- Domain configured: `echo "127.0.0.1 peferrei.42.fr" | sudo tee -a /etc/hosts`

### Start the Project

Open a terminal in the project root folder and run:

```bash
make
```

Or equivalently:

```bash
make build
```

This will:
- Build all Docker images
- Start all containers in the background
- Set up the WordPress site automatically

> ⏱️ First startup may take 1-2 minutes while WordPress downloads and configures.

### Stop the Project

| Command | What It Does |
|---------|--------------|
| `make down` | Gracefully stop and remove containers (data is preserved) |
| `make kill` | Force stop all containers immediately |
| `make clean` | Stop containers AND delete all data volumes |
| `make fclean` | Full cleanup: containers, volumes, images, and networks |

### Restart the Project

```bash
make restart
```

This performs a clean restart (stops, removes volumes, and rebuilds).

---

## Accessing the Website

### WordPress Website (Frontend)

**URL:** [https://peferrei.42.fr](https://peferrei.42.fr)

> ⚠️ **Security Warning:** Your browser will display a certificate warning because the SSL certificate is self-signed. This is normal for development environments.
>
> To proceed:
> - **Chrome:** Click "Advanced" → "Proceed to peferrei.42.fr (unsafe)"
> - **Firefox:** Click "Advanced" → "Accept the Risk and Continue"

### WordPress Admin Panel

**URL:** [https://peferrei.42.fr/wp-admin](https://peferrei.42.fr/wp-admin)

Use the administrator credentials (see below) to log in.

### What You Can Do in the Admin Panel

- Create and edit posts/pages
- Manage users and permissions
- Install themes and plugins
- Configure site settings
- View site statistics

---

## Managing Credentials

### Credential Locations

All credentials are stored in the environment file:

```
srcs/.env
```

### Default Credentials

#### WordPress Admin Account
| Field | Value |
|-------|-------|
| Username | `theroot` |
| Password | `123` |
| Email | `theroot@123.com` |

#### WordPress Editor Account
| Field | Value |
|-------|-------|
| Username | `theuser` |
| Password | `abc` |
| Email | `theuser@123.com` |

#### Database Access
| Field | Value |
|-------|-------|
| Database Name | `thedatabase` |
| Database User | `theuser` |
| Database Password | `abc` |
| Root Password | `123` |

### Changing Credentials

1. **Stop the project:**
   ```bash
   make down
   ```

2. **Edit the environment file:**
   ```bash
   nano srcs/.env
   ```

3. **Modify the desired values:**
   ```env
   # Database settings
   DB_NAME=your_database_name
   DB_USER=your_db_user
   DB_PASSWORD=your_secure_password
   DB_PASS_ROOT=your_root_password

   # WordPress settings
   WP_ADMIN_USER=your_admin_username
   WP_ADMIN_PASSWORD=your_admin_password
   WP_ADMIN_EMAIL=your@email.com
   ```

4. **Clean and rebuild:**
   ```bash
   make fclean
   make build
   ```

> ⚠️ **Important:** After changing database credentials, you must run `make fclean` to reset the database, or the old credentials will still be active.

### Security Recommendations

For production use, change all default passwords to strong, unique values:
- Use at least 12 characters
- Include uppercase, lowercase, numbers, and symbols
- Never reuse passwords

---

## Checking Service Status

### Quick Status Check

```bash
make status
```

This displays all running containers with their status.

**Expected output when healthy:**
```
CONTAINER ID   IMAGE            STATUS          PORTS
abc123         inception-nginx  Up X minutes    0.0.0.0:443->443/tcp
def456         inception-wp     Up X minutes    9000/tcp
ghi789         inception-db     Up X minutes    3306/tcp
```

### Detailed Container Information

View all containers (including stopped):
```bash
docker ps -a
```

### Viewing Logs

Check logs for troubleshooting:

| Command | Description |
|---------|-------------|
| `docker logs nginx` | View Nginx web server logs |
| `docker logs wordpress` | View WordPress/PHP-FPM logs |
| `docker logs mariadb` | View database logs |
| `docker logs -f nginx` | Follow logs in real-time (Ctrl+C to exit) |

### Testing Services Manually

#### Test Nginx (Web Server)
```bash
curl -k https://peferrei.42.fr
```
Expected: HTML content from WordPress

#### Test WordPress (PHP)
```bash
docker exec wordpress php -v
```
Expected: PHP version information

#### Test MariaDB (Database)
```bash
docker exec mariadb mariadb -u theuser -pabc -e "SHOW DATABASES;"
```
Expected: List of databases including `thedatabase`

### Common Issues and Solutions

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| "Connection refused" | Containers not running | Run `make build` |
| "502 Bad Gateway" | WordPress container not ready | Wait 30 seconds and refresh |
| "Database connection error" | MariaDB not ready or wrong credentials | Check logs with `docker logs mariadb` |
| Page loads but looks broken | Volumes not mounted correctly | Run `make fclean && make build` |
| Certificate error | Self-signed certificate | Accept the security exception in browser |

### Health Check Commands

Run these to verify everything is working:

```bash
# 1. Check all containers are running
make status

# 2. Check Nginx is serving HTTPS
curl -k -I https://peferrei.42.fr

# 3. Check database is accessible
docker exec mariadb mariadb -u theuser -pabc -e "SELECT 1;"

# 4. Check PHP is working
docker exec wordpress php -v

# 5. Check WordPress files exist
docker exec wordpress ls -la /var/www/inception/
```

---

## Data Locations

Your data is persisted in these locations on the host machine:

| Data | Location |
|------|----------|
| WordPress files | `~/data/wordpress_files/` |
| Database files | `~/data/database/` |

### Backup Your Data

```bash
# Backup WordPress files
cp -r ~/data/wordpress_files ~/backup/wordpress_$(date +%Y%m%d)

# Backup database
docker exec mariadb mariadb-dump -u root -p123 thedatabase > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat backup_YYYYMMDD.sql | docker exec -i mariadb mariadb -u root -p123 thedatabase
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start project | `make` or `make build` |
| Stop project | `make down` |
| View status | `make status` |
| View logs | `docker logs <container_name>` |
| Full reset | `make fclean && make build` |
| Access website | https://peferrei.42.fr |
| Access admin | https://peferrei.42.fr/wp-admin |
| Edit credentials | `nano srcs/.env` |