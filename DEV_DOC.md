# Developer documentation - Inception project

## Prerequisites

- Virtual machine with Debian Bookworm (or similar)
- Docker Engine installed: https://docs.docker.com/engine/install/debian/
- Docker-compose-plugin installed (pour docker compose)
- `make` available
- `sudo` rights on the VM
- `git` available
- `docker` available
- `vim` available

Add domain to `/etc/hosts`:
```bash
sudo sh -c 'echo "127.0.0.1 makoon.42.fr" >> /etc/hosts'
```

## Environment setup from scratch

### .Env file

Create a `.env` file at the root of the project:
```env
DOMAIN_NAME=makoon.42.fr

# MYSQL SETUP/mariadb
DB_NAME=wordpress
DB_USER=wpuser
DB_PASSWORD=wppassword
DB_ROOT_PASSWORD=rootpassword

# Wordpress
WP_ADMIN_USER=makoon
WP_ADMIN_PASSWORD=makoonpass
WP_ADMIN_EMAIL=makoon@makoon.42.fr
WP_USER=regularuser
WP_USER_PASSWORD=userpassword
WP_USER_EMAIL=user@makoon.42.fr
WP_VERSION=6.5.3
WP_TITLE=inception
```

### Secrets

Create a `/secrets` folder at the root of the project with 3 files :
- `db_password.txt` : contains MariaDB password
- `db_root_password.txt` : contains root password
- `credentials.txt` : contains password of wordpress admin and password of the regular user.


## Build and launch the project

### Makefile

Important concepts :
- Docker image : an immutable template containing the environnement and the application
- Docker container : a running instance of an image
- `build` : builds an image from a Dockerfile
- `up` : creates and starts the containers
- `--build` : forces the images to be rebuilt before launching

Complete Process :
1. The Makefile executes the `docker compose` command.
2. Docker compose has opened the docker-compose.yml file.
3. For each service containing `build`, Docker builds an image from the Dockerfile.
4. Once the images are built, Docker creates from theses images, the corresponding containers.
5. Finally, the containers are launched and the services start.

### Docker compose

#### Build an image

In docker compose in order to build our own images, `build` is used, rather than `image` because it uses the official Docker Hub images.

`build` is used in the compose file, and everything is launched via `docker compose up --build`.
For example, in docker compose : 
```bash
services:
  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
  
  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
  
  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"
```

rather than :
```bash
services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"

  wordpress:
    image: wordpress:php8.2-fpm

  mariadb:
    image: mariadb:11
```

`build` specifies the build context (the folder), not directly the path of Dockerfile. Docker will automatically look for : ./requirements/nginx/Dockerfile.

If the `container_name` is not specified, Docker compose will automatically create a name based on the project, the service and a number (like `inception-nginx-1` or `srcs-nginx-1`). But with `container_name`, the container will called exactly `nginx` for instance and it will be easier to use with commands (for example `docker exec -it nginx bash`).

#### Communication between container : networks

By default, each container is isolated. So without a common network, they can not communicated with each other. When Docker compose creates a network, all containers join the same private network and each container receives a private IP address and an internal DNS entry.

When we used `build`, docker compose automatically creates a network with the name of project (`inception_default`) and connects all services to it.

To declare our own network:
```bash
networks:
  inception:
    driver: bridge
```
`driver` defines how containers are connected to each other. `bridge` is the driver by default for Docker compose (so not necessary to specify) and it`s private network (all containers on the network can communicate but they are isolated from the rest of the system).

To attach services to the network
```bash
services:
 mariadb:
  build: ./requirements/mariadb
  networks:
    - inception
```
Docker compose will create `inception` instead of `inception_default`.

#### Dependencies between services

To express the dependency between services, `depends_on` is used. It defines an order.
For example :
```bash
wordpress:
  depends_on:
    - mariadb
```
It means that mariadb start before wordpress. But it doesn't mean the he is waiting for the database to be ready. So wordpress may then fail to start.

In order to fix this problem (to wait until the service is actually ready), wordpress needs to be linked to the healcheck result.
```bash
wordpress:
  depends_on:
    mariadb:
      condition: service_healthy
```
It means that only start Wordpress when MariaDB is considered healthy.
Without `depends_on`, Compose can launch containers almost in parallel and Wordpress may then fail to start because Wordpress connects to MariaDB, but the database is not ready yet.

#### Retain data

To retain data even if the container is deleted, `volumes` is used. The data (like users, posts, comments for mariadb) is stored in the volume, not in the container.

To define name and option volumes:
```bash
volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/makoon/data/mariadb
```
`driver` instructs Docker to use the local driver (default driver, so no madatory to specify).
`driver_opts` allows to tell the local driver that instead of storing data in `/var/lib/docker/volumes`, use the `/home/makoon/data/mariadb` folder.
`type: none` with `o: bind` indicates that we want to do a bind mount and not use a particular filesystem.

To attach this volume to file `/var/lib/mysql` (where MariaDB stores its database).
```bash
services:
  mariadb:
    volumes:
      - mariadb:/var/lib/mysql
```
mariadb:/var/lib/mysql
│       │
│       └── path in container
│
└── volume name

The volume `wordpress:/var/www/html` is shared between nginx and wordpress because WordPress writes the files and nginx needs to read them.
Without a shared volume, nginx would not see the WordPress files.

#### Communication from PC to a container : ports

To make a service accessible from outside the container, `ports` is used.
Nginx is listening on port 443 inside the container and it's the only service that the browser can connect to. 
MariaDB remains accessible only via the Docker network.

```bash
service:
  nginx:
    ports:
      - "443:443"
```
port_hôte(machine) : port_conteneur(container nginx)

Navigateur
     │
     ▼
localhost:443
     │
     ▼
Docker
     │
     ▼
Conteneur nginx
     │
     ▼
Port 443

If we want to change the port, i.e:
```bash
service:
  nginx:
    ports:
      - "8443:443"
```
We should then visit :
```bash
https://localhost:8443
```

#### Load secrets or environment into containers

To load environment variables into the container, `env_file` is used. The values are visibles in the container.

```bash
services:
  mariadb:
    env_file: .env
```
It's as if we had written:
```bash
environment:
  DB_NAME=wordpress
  DB_USER=wpuser
```

To tell to Docker that this file contains sensitive data to inject into the containers, `secrets` is used. The secret appears as a temporary file in `/run/secrets/` and the application needs to read this file to retrieve the secret, instead of using a visible variable.

```bash
secrets:
  db_password:
    file: ./secrets/db_password.txt
```
To attach the secrets to the service:
```bash
services:
  mariadb:
    secrets:
      - db_password
      - db_root_password
```




pour entrer dans un container. Par ex celui de mariadb : docker exec -it mariadb bash
pour trouver le fichier utiliser pour source de config : mysql --help | grep -A 1 "Default options"
ca me donne comme info par ex : 
Default options are read from the following files in the given order:
/etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf 
donc ca veut dire que MariaDB lit uniquement ces fichiers :
/etc/my.cnf
/etc/mysql/my.cnf
~/.my.cnf

quand je fais : grep -R "bind-address" /etc/mysql /etc/my.cnf 2>/dev/null
si ca me donne : /etc/mysql/mariadb.conf.d/50-server.cnf:bind-address            = 127.0.0.1
ca veut dire qu'il lit encore bind-address sur localhost alors que nous on voulait 0.0.0.0

pour voir si mariadb ecoute vraiment sur le reseau : ss -lntp | grep 3306
on doit avoir : LISTEN 0      80           0.0.0.0:3306       0.0.0.0:*  

pour voir si le service est accessible depuis wordpress : mariadb -h mariadb -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1"

pour sortir de la : exit



Commands :
- `make` or `make up` : build images and start all containers
- `make down` : stop and remove containers
- `make stop` : stop containers without removing them
- `make start` : start stopped containers
- `make restart` : restart all containers
- `make status` : show running containers
- `make logs` : follow container logs
- `make clean` : remove containers and volumes
- `make fclean` : full cleanup including persistent data
- `make re` : full rebuild


## Useful container management commands

```bash
docker compose -f srcs/docker-compose.yml ps        # Check which containers are up
docker compose -f srcs/docker-compose.yml ps nginx  # Check if nginx is running
docker compose -f srcs/docker-compose.yml ps wordpress
docker compose -f srcs/docker-compose.yml ps mariadb
```

```bash
docker volume ls    # display volume
```


## Data persistence

```bash
ls /home/makoon/data    # check the data file
```

Verify that the database is not empty
```bash
docker exec -it mariadb mysql -u root -p
```
Enter root password, then write in the shell MySQL:
```bash
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;
exit
```
The 2 users WordPress is displayed.

Data survives to `make down`, `make stop` and `make clean`.
Only `make fclean` removes it.
To check the persistence :
```bash
sudo reboot                                 # reboot the VM
make                                        # relaunch the project
docker exec -it mariadb mysql -u root -p    # Verify that the data is still there
USE wordpress;
SELECT * FROM wp_comments;
```

| Data              | Volume name    | Host path                    |
|-------------------|----------------|------------------------------|
| MariaDB database  | `srcs_mariadb` | `/home/login/data/mariadb`   |
| WordPress files   | `srcs_wordpress`| `/home/login/data/wordpress` |


## Project structure

When we go to `https://makoon.42.fr` 

- The browser contacts NGINX. Nginx is the entry point.
- NGINX receives a PHP request like `/index.php` but NGINX doesn't know how to execute PHP. It therefore forwards the request to `wordpress:9000` via FstCGI. That's why WordPress runs with php-fpm.
- WordPress needs the data. WordPress requests :`SELECT * FROM wp_users;` from MariaDB via the Docker network `mariadb:3306`

Docker launches the container and the script is used to install/configure the service, prepare the environment and then launch the main process.

Example MariaDB :

init.sh
 ├─ initialize DB
 ├─ create users/database
 └─ launch mysqld

Example WordPress :

init.sh
 ├─ download wordpress
 ├─ configure wp-config.php
 ├─ create admin
 └─ launch php-fpm