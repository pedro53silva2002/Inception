*This project has been created as part of the 42 curriculum by peferrei.*

# Inception

A Docker-based infrastructure project that sets up a complete LEMP stack (Linux, Nginx, MariaDB, PHP) to host a WordPress website with SSL/TLS encryption.

---

## Description

**Inception** is a system administration project that uses Docker and Docker Compose to create a multi-container infrastructure. The goal is to set up a fully functional WordPress website running on a LEMP stack, with each service isolated in its own container.

### Project Goal

The main objective is to learn about containerization, Docker networking, volumes, and how to orchestrate multiple services using Docker Compose. This project emphasizes:

- Building custom Docker images from Debian base images
- Configuring secure HTTPS connections with self-signed SSL certificates
- Managing data persistence with Docker volumes
- Container orchestration and inter-container communication

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Environment                       │
│                                                              │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────┐   │
│  │  Nginx   │──────│  WordPress   │──────│   MariaDB    │   │
│  │  (443)   │      │   (PHP-FPM)  │      │   (3306)     │   │
│  └──────────┘      └──────────────┘      └──────────────┘   │
│       │                   │                     │            │
│       └───────────────────┴─────────────────────┘            │
│                    Bridge Network                            │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Volumes (Persistent Data)                  │ │
│  │   • wordpress_files: /var/www/inception/                │ │
│  │   • database: /var/lib/mysql/                           │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Services

|    Service    |    Base Image   |      Port      |                     Description                     |
|---------------|-----------------|----------------|-----------------------------------------------------|
| **Nginx**     | debian:bookworm | 443 (HTTPS)    | Web server with TLS 1.2, reverse proxy to WordPress |
| **WordPress** | debian:bookworm | 9000 (PHP-FPM) | PHP-FPM application server with WP-CLI              |
| **MariaDB**   | debian:bookworm | 3306           | Database server for WordPress data                  |

---

## Instructions

### Prerequisites

- Docker Engine (v20.10+)
- Docker Compose (v2.0+)
- Make
- At least 2GB of free disk space

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pedro53silva2002/Inception.git
   cd Inception
   ```

2. **Create data directories:**
   ```bash
   mkdir -p ~/data/database ~/data/wordpress_files
   ```

3. **Configure environment variables:**
   Create environment variables file `srcs/.env`.
   Edit `srcs/.env` to customize your settings (database credentials, WordPress settings, SSL certificate details).

4. **Add the domain to your hosts file:**
   ```bash
   echo "127.0.0.1 peferrei.42.fr" | sudo tee -a /etc/hosts
   ```

### Running the Project

|        Command         |                     Description                      |
|------------------------|------------------------------------------------------|
| `make` or `make build` | Build and start all containers                       |
| `make down`            | Stop and remove containers                           |
| `make clean`           | Stop containers and remove volumes                   |
| `make fclean`          | Full cleanup (containers, volumes, images, networks) |
| `make restart`         | Clean and rebuild all containers                     |
| `make status`          | Show running containers                              |
| `make kill`            | Force stop all containers                            |

### Accessing the Website

Once the containers are running, access WordPress at:
- **URL:** `https://peferrei.42.fr`

> ⚠️ The SSL certificate is self-signed. Your browser will show a security warning — this is expected for development environments.

### Default Credentials

|     Account     | Username | Password |
|-----------------|----------|----------|
| WordPress Admin | theroot  |   123    |
| WordPress User  | theuser  |   abc    |
| Database Root   | root     |   123    |

---

## Project Description

### Docker Usage

This project uses **Docker** to containerize each service, ensuring isolation, reproducibility, and ease of deployment. Each container is built from a `debian:bookworm` base image with only the necessary packages installed.

**Key Docker features used:**

- **Multi-stage builds:** Each Dockerfile installs only required dependencies
- **Health checks:** Containers use `restart: on-failure` for automatic recovery
- **Init process:** `init: true` ensures proper signal handling and zombie process reaping
- **Build arguments:** SSL certificate configuration is passed at build time

### Design Choices

1. **Debian Bookworm as base image:** Chosen for stability and compatibility with 42 project requirements
2. **PHP-FPM 8.2:** Modern PHP version with FastCGI Process Manager for better performance
3. **WP-CLI:** Enables automated WordPress installation and configuration
4. **TLS 1.2:** Secure protocol for HTTPS connections
5. **Bridge network:** Allows containers to communicate while remaining isolated from the host

---

## Technical Comparisons

### Virtual Machines vs Docker

|       Aspect       |           Virtual Machines           |             Docker Containers               |
|--------------------|--------------------------------------|---------------------------------------------|
| **Isolation**      | Full OS isolation with hypervisor    | Process-level isolation sharing host kernel |
| **Resource Usage** | Heavy (GBs of RAM, full OS overhead) | Lightweight (MBs, shared kernel)            |
| **Startup Time**   | Minutes                              | Seconds                                     |
| **Portability**    | Limited by hypervisor compatibility  | Highly portable across any Docker host      |
| **Use Case**       | When full OS isolation is required   | Microservices, development, CI/CD           |

**This project uses Docker** because it provides sufficient isolation for web services while being lightweight and fast to deploy.

---

### Docker Network vs Host Network

|      Aspect      |            Docker Bridge Network            |               Host Network               |
|------------------|---------------------------------------------|------------------------------------------|
| **Isolation**    | Containers have their own network namespace | Shares host's network stack              |
| **Port Mapping** | Required (`-p 443:443`)                     | Not needed, uses host ports directly     |
| **Performance**  | Slight overhead from NAT                    | Native performance                       |
| **Security**     | Better isolation between containers         | Less isolation, potential port conflicts |
| **DNS**          | Built-in DNS for container names            | No automatic DNS resolution              |

**This project uses a bridge network** (`all`) to:
- Enable container name resolution (e.g., `wordpress` can reach `mariadb` by name)
- Maintain network isolation from the host
- Only expose port 443 to the outside world

---

### Docker Volumes vs Bind Mounts

|     Aspect      |        Docker Volumes       |          Bind Mounts          |
|-----------------|-----------------------------|-------------------------------|
| **Management**  | Managed by Docker           | User-managed directories      |
| **Location**    | `/var/lib/docker/volumes/`  | Any path on host              |
| **Portability** | Easy to backup/migrate      | Path-dependent                |
| **Performance** | Optimized for Docker        | Native filesystem performance |
| **Use Case**    | Persistent application data | Development, config files     |

**This project uses named volumes with bind mount drivers:**
```yaml
volumes:
  database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ~/data/database/
```

This hybrid approach provides:
- Named volume semantics (easy management via Docker CLI)
- Bind mount storage (data accessible at `~/data/` on the host)

---

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)

### Tutorials & Articles

- [Docker for Beginners](https://docker-curriculum.com/)
- [Understanding Docker Networking](https://docs.docker.com/network/)
- [SSL/TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [PHP-FPM Configuration Guide](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Docker VS Docker Compose](https://medium.com/@ShantKhayalian/docker-vs-docker-compose-simple-and-fun-explanation-4811582127f7)

### AI Usage

AI assistance (GitHub Copilot) was used for:
- **Documentation:** Generating this README.md file with proper structure and formatting
- **Code review:** Reviewing Dockerfile best practices and suggesting optimizations
- **Troubleshooting:** Debugging container communication and configuration issues

All code logic, architecture decisions, and implementations were done manually by the project author.

---

## License

This project is part of the 42 School curriculum.