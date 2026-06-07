*This project has been created as part of the 42 curriculum by makoon.*

# inception

## Description

This projects aims to introduce system administration and containerization using Docker and Docker Compose.

The goal is to build a small infrastructure composed of multiple interconnected services running inside isolated Docker containers.
Each service has its own dedicated container and configuration.

The infrastructure includes :
- An Nginx web server
- A Wordpress website running with PHP-FPM
- A MariaDB database
- Persistent storage using Docker volumes
- A dedicated Docker network for inter-container communication

Internet / navigateur
        ↓
      NGINX
        ↓
   WORDPRESS (PHP-FPM)
        ↓
     MARIADB

Each container has a specific role :
- Nginx receives HTTPS requests
- Wordpress executes WordPress PHP
- MariaDB stores data.


## Design choices

### Virtual Machines vs Docker

A VM virtualizes an entire operating system including its kernel (complete OS), requiring significant ressources. 
Docker containers share the host kernel and isolate only the application layer, making them much lighter and faster to start.

For this project, Docker allows us to run three isolated services on a single VM minimal overhead.

### Secrets vs Environment Variables

Environment variables (via `.env`) are suitable for non-sensitive configuration like domain names or usernames.
Secrets (files in `secrets/`) are used for passwords and credentials (they are never written into a Dockerfile or committed to Git, reducing the exposure in case of a repository leak).

In this project, secrets are used for passwords and environment variables are used for the rest.

### Docker Network vs Host Network

A Docker bridge network (`inception`) creates a virtual private network between containers. It isolates container communication from the host network. Only what is explicitly exposed with `ports:` is accessible from the outside (here port 443).
With `network: host`, the container directly shares the host machine's network. All container ports would be directly exposed on the host (a significant security risk forbidden by the subject).

A dedicated Docker network is used in this project to ensure secure and organized communication between services.

### Docker Volumes vs Bind Mount

Named volumes are managed by Docker and persist independently of the container lifecycle. The data survives to `docker compose down`.
Bind mounts directly map a host path into a container, which is less portable and harder to manage because it depends to the host machine.

This project uses named volumes with a local driver pointing to `/home/makoon/data` to satisfy both the persistence and the named volume requirements.
Docker volumes are used to persist Wordpress and MariaDB data.

### NGINX : Web server

The role of NGINX is to receive the HTTP/HTTPS requests and to send them to WordPress. 

In Dockerfile :
- install nginx
- install openssl (used to generate SSL/TLS certificat)
- copy of nginx.conf

The .conf file :
- indicates on which port and in which mode the server listens for connections : server listens on port 443 and on mode SSL/TLS (HTTPS)
```bash
server {
	listen 443 ssl;       # for IPv4
	listen [::]:443 ssl;  # for IPv6
}
```
- specifies that this server must respond to a specific domain name
```bash
server {
  server_name makoon.42.fr;
}
```
- definies the server's public SSL certificate and the private key associated with the certificate, and also specifies which versions of HTTPS protocol are allowed
```bash
server {
	ssl_certificate /etc/nginx/ssl/nginx.crt;
	ssl_certificate_key /etc/nginx/ssl/nginx.key;

	ssl_protocols TLSv1.2 TLSv1.3;
}
```
- definies where the site files are located and which file to display by default
```bash
server {
	root /var/www/wordpress;
	index index.php index.html index.htm;
}
```
- specifies how to handle PHP with Nginx --> send PHP requests to the WordPress service on port 9000 via FastCGI because in WordPress (PHP-FPM), the process PHP listens on port 9000.
```bash
server {
	location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;  # service_name(on docker-compose.yml):port_interne (port where PHP-FPM runs in wordpress container)
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
	location / {
		try_files $uri $uri/ /index.php?$args;
	}
}
```

### MariaDB : database

The role of MariaDB is to store the WordPress data.

In Dockerfile :
- install mariadb-server
- copy of mariadb.conf.d/50-server.cnf (on which network interface does MariaDB listen for connections)
- copy the script init.sh (creation of DB + user)

In init.sh :
- prepare the system directory necessary for MariaDB (/run/mysqld)
- check if the database already exists
- if not :
  - initialise a new database (mysql_install_db)
  - automatically create the WordPress database(DB_NAME), a WordPress user (DB_USER), the permissions on this database and the root password.
  - execute the SQL on the first startup
- then, launch MariaDB (mysql)
- if the database already exists, simply start MariaDB without resetting anything.

This script is used to initialize and start MariaDB in the container automatically.

In 50-server.cnf :
- MariaDB need to accept connections from any network address because WordPress is in a different container. By default, MariaDB listens on 127.0.0.1 (localhost), so only accessible from the same container and no one from outside can connect.
Without `bind-address = 0.0.0.0, WordPress may receive errors such as :
```bash
Can't connect to MySQL server
```
even if MariaDB is well started.

### WordPress : PHP-FPM

The role of WordPress is to generate a dynamic website.

In Dockerfile :
- install php8.2-fpm (PHP FastCGI server because Nginx cannot execute PHP directly, so it allows PHP to communicate with MariaDB/MySQL and 8.2 version for the compatibility with debian:bookworm)
- install various extensions : php8.2-mysql (connexion to mariadb), php8.2-curl (HTTP request from PHP), php8.2-mbstring (for special characters)
- install wget or curl (to download WordPress)
- install tar (to decompress the file)
- copy php www.conf (php-fpm listens on the Docker network; therefore, PHP-FPM listens on 0.0.0.0:9000 instead of 127.0.0.1:9000 because nginx is in a different container)
- copy the script setup.sh (the script allows to download WordPress, configure wp-config.php, connect MariaDB, and launch php-fpm)
- install wp-cli (used to automatically install WordPress, create an admin area, and configure the site without a browser)

In www.conf :
- On which port PHP-FPM listen (PHP-FPM listens on port 9000, so Nginx can send it requests with `fastcgi_pass wordpress:9000`)
- tell who has the right to communicate on this port/socket
```bash
listen.owner = www-data # only the www-data user can access
listen.group = www-data # the www-data group can also access
```
`www-data` is the standard Linux user, already intended for web servers used for nginx, apache and php-fpm .

In setup.sh :
- automate the Wordpress installation by :
  - preparing thhe WordPress folder (create `/var/www/wordpress` if necessary and give the permissions to `www-data`)
  - downloading WordPress at the first launch with WP-CLI and generating the configuration file containing the MariaDB connection parameters
  - waiting that MariaDB is ready
  - set up WordPress if it's not already done (creation of WordPress website, configuration of URL, title, admin account and creation of a regular user)
- then start PHP-FPM


## Instructions

All containers are build from scratch using custom Dockerfiles based on Debian Bookworm (penultimate stable version of Debian at this moment).

In the WordPress database, there must be 2 users and one of them is the administator.

Each Docker image have the same name as its corresponding service. Each service runs in a dedicated container.

### Prerequisites

- Docker and Docker compose installed
- A virtual machine running Debian or similar
- `sudo` access to edit `/etc/hosts`

### Environment variables

Create a `/secrets` folder at the root of the project with 4 files :
- `db_password.txt` : contains MariaDB password
- `db_root_password.txt` : contains root password
- `wp_admin_password.txt` : contains password of wordpress admin
- `wp_user_password.txt` : contains password of the regular user.

```bash
mkdir secret
cd secret/
echo "wppassword" > db_password.txt
echo "rootpassword" > db_root_password.txt
echo "makoonpass" > wp_admin_password.txt
echo "userpassword" > wp_user_password.txt
```

Create a `.env` file in folder `srcs/`:
```bash
cd srcs/
touch .env
```

Example of `.env`: 
```env
DOMAIN_NAME=makoon.42.fr

# MYSQL SETUP/mariadb
DB_NAME=wordpress
DB_USER=wpuser

# Wordpress
WP_ADMIN_USER=makoon
WP_ADMIN_EMAIL=makoon@makoon.42.fr
WP_USER=regularuser
WP_USER_EMAIL=user@makoon.42.fr
WP_VERSION=6.5.3
WP_TITLE=inception
```

Add domain to `/etc/hosts`:
```bash
sudo sh -c 'echo "127.0.0.1 makoon.42.fr" >> /etc/hosts'
```


### Build and run

The Dockerfiles are called in the docker-comnpose.yml by the Makefile.

The project must be compiled using :
```bash
make
```

All available commands included on Makefile :

| Command             | Description                              |
|---------------------|------------------------------------------|
| `make` or `make up` | Build images and start all containers    |
| `make down`         | Stop and remove containers               |
| `make stop`         | Stop containers without removing them    |
| `make start`        | Start stopped containers                 |
| `make restart`      | Restart all containers                   |
| `make status`       | Show running containers                  |
| `make logs`         | Follow container logs                    |
| `make clean`        | Remove containers and volumes            |
| `make fclean`       | Full cleanup including persistent data   |
| `make re`           | Full rebuild from scratch                |


### Access

Once all containers are running:
- Open Wordpress website: https://makoon.42.fr and accept the SSL warning
- Nginx listens on port 443 (HTTPS only)


## Ressources

Stable version of Debian : https://www.debian.org/releases/index.fr.html
Tuto : https://tuto.grademe.fr/inception/
https://www.atlantic.net/dedicated-server-hosting/how-to-install-and-use-mariadb-on-debian-12/

Docker Compose documentation : https://docs.docker.com/compose/

Nginx documentation : https://nginx.org/en/docs/

MariaDB Documentation : https://mariadb.org/documentation/

MariaDB healthcheck: https://mariadb.org/mariadb-server-docker-official-images-healthcheck-without-mysqladmin/
https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/using-healthcheck-sh

WordPress Documentation : https://wordpress.org/documentation/


### AI usage

ChatGPT and Claude (Anthropic) were used during this project for explaining concepts and debugging.
