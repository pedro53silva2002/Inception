# Inception - Developer Documentation

This guide provides technical documentation for developers working on the Inception project.

---

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Building and Launching](#building-and-launching)
3. [Container and Volume Management](#container-and-volume-management)
4. [Data Storage and Persistence](#data-storage-and-persistence)

---

## Environment Setup

### Prerequisites

Ensure the following are installed on your system:

|  Requirement   | Minimum Version |                               Installation                                |
|----------------|-----------------|---------------------------------------------------------------------------|
| Docker Engine  | 20.10+          | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/) |
| Docker Compose | 2.0+ (V2)       | Included with Docker Desktop or `docker-compose-plugin`                   |
| Make           | 4.0+            | `sudo apt install make`                                                   |
| Git            | 2.0+            | `sudo apt install git`                                                    |

Verify installations:

```bash
docker --version
docker compose version
make --version
```

### Project Structure

```
Inception/
├── Makefile                    # Build automation
├── README.md                   # Project overview
├── USER_DOC.md                 # End-user documentation
├── DEV_DOC.md                  # This file
└── srcs/
    ├── .env                    # Environment variables (secrets)
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile      # MariaDB image definition
        │   ├── conf/
        │   │   └── 50-server.cnf   # MariaDB configuration
        │   └── tools/
        │       └── setup.sh    # Database initialization script
        ├── nginx/
        │   ├── Dockerfile      # Nginx image definition
        │   ├── conf/
        │   │   ├── nginx.conf      # Main Nginx configuration
        │   │   └── server.conf     # Virtual host configuration
        │   └── tools/
        └── wordpress/
            ├── Dockerfile      # WordPress image definition
            ├── conf/
            │   ├── wp-config.php   # WordPress configuration
            │   └── www.conf        # PHP-FPM pool configuration
            └── tools/
                └── setup.sh    # WordPress installation script
```

### Configuration Files

#### 1. Environment Variables (`srcs/.env`)

This file contains all secrets and configuration values. **Never commit real credentials to version control.**

```env
# Database settings
DB_NAME=thedatabase           # WordPress database name
DB_USER=theuser               # Database user for WordPress
DB_PASSWORD=abc               # Database user password
DB_PASS_ROOT=123              # MariaDB root password
DB_HOST=mariadb               # Database hostname (container name)

# WordPress settings
WP_URL=peferrei.42.fr         # Site URL (without protocol)
WP_TITLE=Inception            # Site title
WP_ADMIN_USER=theroot         # Admin username
WP_ADMIN_PASSWORD=123         # Admin password
WP_ADMIN_EMAIL=theroot@123.com
WP_USER=theuser               # Secondary user
WP_PASSWORD=abc               # Secondary user password
WP_EMAIL=theuser@123.com
WP_ROLE=editor                # Secondary user role
WP_FULL_URL=https://peferrei.42.fr

# SSL Certificate settings
CERT_FOLDER=/etc/nginx/certs/
CERTIFICATE=/etc/nginx/certs/certificate.crt
KEY=/etc/nginx/certs/certificate.key
COUNTRY=BR
STATE=BA
LOCALITY=Salvador
ORGANIZATION=42
UNIT=42
COMMON_NAME=peferrei.42.fr    # Must match WP_URL
```

#### 2. MariaDB Configuration (`srcs/requirements/mariadb/conf/50-server.cnf`)

```ini
[mysqld]
port=3306
```

Minimal configuration. MariaDB listens on port 3306 within the container network.

#### 3. Nginx Configuration (`srcs/requirements/nginx/conf/nginx.conf`)

Main configuration defining:
- Worker processes (auto-detected)
- Upstream PHP-FPM server (`wordpress:9000`)
- Logging format and locations
- Include directive for virtual hosts

#### 4. Nginx Virtual Host (`srcs/requirements/nginx/conf/server.conf`)

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_protocols TLSv1.2;
    root /var/www/inception/;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

SSL certificate paths are injected at build time via Dockerfile.

#### 5. WordPress Configuration (`srcs/requirements/wordpress/conf/wp-config.php`)

```php
define( 'DB_NAME', getenv('DB_NAME') );
define( 'DB_USER', getenv('DB_USER') );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') );
define( 'DB_HOST', getenv('DB_HOST') );
define( 'WP_HOME', getenv('WP_FULL_URL') );
define( 'WP_SITEURL', getenv('WP_FULL_URL') );
```

All sensitive values are read from environment variables at runtime.

### Initial Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pedro53silva2002/Inception.git
   cd Inception
   ```

2. **Create required data directories:**
   ```bash
   mkdir -p ~/data/database ~/data/wordpress_files
   ```

3. **Configure your domain in `/etc/hosts`:**
   ```bash
   echo "127.0.0.1 peferrei.42.fr" | sudo tee -a /etc/hosts
   ```

4. **Customize environment variables (optional):**
   ```bash
   cp srcs/.env srcs/.env.backup
   nano srcs/.env
   ```

5. **Verify Docker is running:**
   ```bash
   sudo systemctl status docker
   # If not running:
   sudo systemctl start docker
   ```

---

## Building and Launching

### Makefile Targets

| Target | Command | Description |
|--------|---------|-------------|
| `all` | `make` | Alias for `build` |
| `build` | `make build` | Build images and start containers in detached mode |
| `down` | `make down` | Stop and remove containers (preserves volumes) |
| `kill` | `make kill` | Force stop all containers |
| `clean` | `make clean` | Stop containers and remove volumes |
| `fclean` | `make fclean` | Full cleanup: `clean` + prune all Docker resources |
| `restart` | `make restart` | Execute `clean` then `build` |
| `status` | `make status` | Display running containers |

### Build Process

```bash
make build
```

This executes:
```bash
docker compose -f ./srcs/docker-compose.yml up --build -d
```

**What happens during build:**

1. **MariaDB container:**
   - Builds from `debian:bookworm`
   - Installs `mariadb-server`
   - Copies configuration and setup script
   - Runs `setup.sh` on startup which:
     - Starts MariaDB service
     - Creates database and users
     - Sets passwords
     - Restarts in safe mode

2. **WordPress container:**
   - Builds from `debian:bookworm`
   - Installs PHP 8.2 FPM, MySQL extension, wget
   - Downloads WP-CLI
   - Copies configuration files
   - Runs `setup.sh` on startup which:
     - Downloads WordPress core
     - Copies `wp-config.php`
     - Installs WordPress (if not installed)
     - Creates admin and editor users
     - Installs and activates theme

3. **Nginx container:**
   - Builds from `debian:bookworm`
   - Installs nginx and openssl
   - Generates self-signed SSL certificate using build args
   - Copies configuration files
   - Injects certificate paths into server confi
Ensure the following are installedg

### Docker Compose Configuration

Key settings in `srcs/docker-compose.yml`:

```yaml
services:
  mariadb:
    container_name: mariadb
    build: ./requirements/mariadb/
    volumes:
      - database:/var/lib/mysql/
    networks:
      - all
    init: true                    # Proper signal handling
    restart: on-failure           # Auto-restart on crash
    env_file:
      - .env

  wordpress:
    container_name: wordpress
    build: ./requirements/wordpress/
    volumes:
      - wordpress_files:/var/www/inception/
    networks:
      - all
    depends_on:
      - mariadb                   # Start order dependency

  nginx:
    container_name: nginx
    build:
      context: ./requirements/nginx/
      args:                       # Build-time variables for SSL
        CERT_FOLDER: ${CERT_FOLDER}
        CERTIFICATE: ${CERTIFICATE}
        # ... other SSL args
    ports:
      - '443:443'                 # Only exposed port
    volumes:
      - wordpress_files:/var/www/inception/  # Shared with WordPress
    depends_on:
      - wordpress
```

### Startup Order

```
1. MariaDB starts → initializes database
2. WordPress starts → waits for MariaDB, installs WordPress
3. Nginx starts → serves requests, proxies to WordPress
```

The `depends_on` directive ensures correct startup order, and WordPress `setup.sh` includes a `sleep 10` to wait for MariaDB initialization.

---

## Container and Volume Management

### Container Commands

#### View running containers
```bash
make status
# or
docker ps
```

#### View all containers (including stopped)
```bash
docker ps -a
```

#### View container logs
```bash
docker logs <container_name>
docker logs nginx
docker logs wordpress
docker logs mariadb

# Follow logs in real-time
docker logs -f wordpress
```

#### Execute commands inside containers
```bash
docker exec -it <container_name> <command>

# Examples:
docker exec -it mariadb bash                    # Interactive shell
docker exec -it wordpress bash
docker exec -it nginx bash

docker exec wordpress php -v                     # Check PHP version
docker exec mariadb mariadb -u root -p123 -e "SHOW DATABASES;"
docker exec wordpress wp --allow-root --path="/var/www/inception/" plugin list
```

#### Inspect container details
```bash
docker inspect <container_name>
docker inspect nginx | grep IPAddress
docker inspect wordpress --format='{{.State.Status}}'
```

#### View container resource usage
```bash
docker stats
```

### Network Commands

#### List networks
```bash
docker network ls
```

#### Inspect the project network
```bash
docker network inspect srcs_all
```

#### Test inter-container connectivity
```bash
docker exec wordpress ping -c 3 mariadb
docker exec nginx ping -c 3 wordpress
```

### Volume Commands

#### List volumes
```bash
docker volume ls
```

Expected volumes:
```
DRIVER    VOLUME NAME
local     srcs_database
local     srcs_wordpress_files
```

#### Inspect volume details
```bash
docker volume inspect srcs_database
docker volume inspect srcs_wordpress_files
```

#### View volume contents
```bash
# Via container
docker exec wordpress ls -la /var/www/inception/
docker exec mariadb ls -la /var/lib/mysql/

# Directly on host
ls -la ~/data/wordpress_files/
ls -la ~/data/database/
```

#### Remove specific volume
```bash
docker volume rm srcs_database
docker volume rm srcs_wordpress_files
```

#### Remove all unused volumes
```bash
docker volume prune
```

### Image Commands

#### List images
```bash
docker images
```

#### Remove project images
```bash
docker rmi srcs-nginx srcs-wordpress srcs-mariadb
```

#### Rebuild without cache
```bash
docker compose -f srcs/docker-compose.yml build --no-cache
docker compose -f srcs/docker-compose.yml up -d
```

### Cleanup Commands

| Scope | Command | Effect |
|-------|---------|--------|
| Stop containers | `make down` | Containers removed, volumes preserved |
| Stop + delete volumes | `make clean` | All data deleted |
| Full cleanup | `make fclean` | Containers, volumes, images, networks deleted |
| System prune | `docker system prune -a -f` | Remove all unused Docker resources |

---

## Data Storage and Persistence

### Volume Architecture

The project uses **named volumes with bind mount drivers** to persist data:

```yaml
volumes:
  database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ~/data/database/

  wordpress_files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ~/data/wordpress_files/
```

### Data Locations

| Data Type | Container Path | Host Path | Description |
|-----------|---------------|-----------|-------------|
| Database | `/var/lib/mysql/` | `~/data/database/` | MariaDB data files |
| WordPress | `/var/www/inception/` | `~/data/wordpress_files/` | WordPress core, themes, plugins, uploads |

### How Persistence Works

1. **On first run:**
   - Docker creates volumes linked to host directories
   - MariaDB initializes database files in `~/data/database/`
   - WordPress downloads core files to `~/data/wordpress_files/`

2. **On container restart:**
   - Containers attach to existing volumes
   - Data is preserved between restarts

3. **On `make down`:**
   - Containers are removed
   - Volumes and data persist

4. **On `make clean` or `make fclean`:**
   - Volumes are deleted
   - Host directories are NOT automatically deleted
   - Data may still exist in `~/data/`

### Shared Volumes

The `wordpress_files` volume is shared between WordPress and Nginx:

```
WordPress container                 Nginx container
       ↓                                  ↓
/var/www/inception/ ←── volume ──→ /var/www/inception/
       ↓                                  ↓
    (writes PHP)                    (reads static files)
```

This allows:
- WordPress to process PHP files
- Nginx to serve static assets (CSS, JS, images) directly

### Backup Procedures

#### Database Backup
```bash
# Export database to SQL file
docker exec mariadb mariadb-dump -u root -p123 thedatabase > backup_db_$(date +%Y%m%d).sql

# With compression
docker exec mariadb mariadb-dump -u root -p123 thedatabase | gzip > backup_db_$(date +%Y%m%d).sql.gz
```

#### WordPress Files Backup
```bash
# Copy WordPress files
cp -r ~/data/wordpress_files ~/backup/wordpress_$(date +%Y%m%d)

# With compression
tar -czvf backup_wordpress_$(date +%Y%m%d).tar.gz ~/data/wordpress_files
```

#### Full Backup Script
```bash
#!/bin/bash
BACKUP_DIR=~/backups/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# Database
docker exec mariadb mariadb-dump -u root -p123 thedatabase > $BACKUP_DIR/database.sql

# WordPress files
cp -r ~/data/wordpress_files $BACKUP_DIR/wordpress

echo "Backup completed: $BACKUP_DIR"
```

### Restore Procedures

#### Restore Database
```bash
# From SQL file
cat backup_db_YYYYMMDD.sql | docker exec -i mariadb mariadb -u root -p123 thedatabase

# From compressed file
gunzip -c backup_db_YYYYMMDD.sql.gz | docker exec -i mariadb mariadb -u root -p123 thedatabase
```

#### Restore WordPress Files
```bash
# Stop containers first
make down

# Restore files
rm -rf ~/data/wordpress_files/*
cp -r ~/backup/wordpress_YYYYMMDD/* ~/data/wordpress_files/

# Restart
make build
```

### Data Reset

To completely reset all data:

```bash
# 1. Stop and remove everything
make fclean

# 2. Delete host data directories
rm -rf ~/data/database ~/data/wordpress_files

# 3. Recreate directories
mkdir -p ~/data/database ~/data/wordpress_files

# 4. Rebuild from scratch
make build
```

### Debugging Data Issues

#### Check if volumes are mounted correctly
```bash
docker inspect wordpress --format='{{json .Mounts}}' | jq
```

#### Verify file ownership
```bash
docker exec wordpress ls -la /var/www/inception/
# Files should be owned by www-data:www-data
```

#### Fix permissions
```bash
docker exec wordpress chown -R www-data:www-data /var/www/inception/
```

#### Check database connectivity
```bash
docker exec wordpress php -r "
\$conn = new mysqli('mariadb', 'theuser', 'abc', 'thedatabase');
if (\$conn->connect_error) {
    die('Connection failed: ' . \$conn->connect_error);
}
echo 'Connected successfully';
"
```

---

## Development Workflow

### Making Changes to Dockerfiles

1. Edit the Dockerfile
2. Rebuild the specific service:
   ```bash
   docker compose -f srcs/docker-compose.yml build <service_name>
   docker compose -f srcs/docker-compose.yml up -d <service_name>
   ```

### Making Changes to Configuration Files

Configuration files are copied at build time, so you need to rebuild:

```bash
# After editing nginx.conf, server.conf, 50-server.cnf, etc.
make restart
```

### Making Changes to Environment Variables

```bash
# Edit .env
nano srcs/.env

# Restart containers (no rebuild needed for most env vars)
make down
make build
```

### Testing Changes

```bash
# Quick syntax check for nginx config
docker exec nginx nginx -t

# Reload nginx without restart
docker exec nginx nginx -s reload

# Check WordPress configuration
docker exec wordpress wp --allow-root --path="/var/www/inception/" config list
```