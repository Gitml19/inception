# User documentation - Inception project

## Services provided

This stack runs a Wordpress website accessible via HTTPS, backed by a MariaDB database.

Three services are running:
| Service   | Role                              | Port |
|-----------|-----------------------------------|------|
| NGINX     | Web server / HTTPS entrypoint     | 443  |
| WordPress | Application (php-fpm)             | 9000 (internal only) |
| MariaDB   | Database                          | 3306 (internal only) |


## Start and stop the project

```bash
make            # Start everything
make down       # Stop without losing data
make fclean     # Stop and remove all data
```

## Access the website

- Website : `https://makoon.42.fr`
- WordPress administration panel : `https:\\makoon.42.fr/wp-admin`

The browser will show an SSL warning because the certificate is self-signed.
Click 'Advanced...' then 'Accept the Risk and Continue' to continue.

The website can only have access via https.
HTTP (port 80) should not work:
```bash
curl http://makoon.42.fr    # display "Could not connect to server"
```

## Credentials

All credentials are stored in:
- `srcs/.env` : usernames, database name, domain
- `secrets/db_password.txt` : database user password
- `secrets/db_root_password.txt` : database root password
- `secrets/credentials.txt` : Wordpress admin credentials

Docker compose makes secrets available inside containers at:
- `/run/secrets/db_password`
- `/run/secrets/db_root_password`
- `/run/secrets/credentials`

Secrets can be read using, for example :
```bash
cat /run/secrets/db_password
```

Example usage in MariaDB init script:
```bash
DB_PASSWORD=$(cat /run/secrets/db_password) # instead of having for example DB_PASSWORD=wppassword
```

**Never commit these files to Git.**

## Check that services are running

```bash
make status             # See all running containers and their status
docker compose -f srcs/docker-compose.yml ps        # Check which containers are up
docker compose -f srcs/docker-compose.yml ps nginx  # Check if nginx is running
docker compose -f srcs/docker-compose.yml ps wordpress
docker compose -f srcs/docker-compose.yml ps mariadb
make logs               # Follow live logs
make logs -f <service>  # Follow logs for one specific service i.e. make logs -f nginx
```

All three containers should show status `Up`. If one is restarting repeatedly, check its logs for errors.



Check that NGINX can be accessed by port 443 only (no other ports):
```bash
docker compose -f srcs/docker-compose.yml ps | grep 443
```
The service is exposed only on port 443 on the host machine.

Check docker image name:
```bash
docker images
```

Verify that docker-network is used :
```bash
docker network ls                   # display "inception"
docker network inspect inception    # show that the 3 containers is connected inside
```

Check the volume :
```bash
docker volume ls
docker volume inspect srcs_mariadb  # mariadb volume for example
```

How to login to database :
- Enter into the container
```bash
docker exec -it mariadb bash
```
- Connect to service:
```bash
mysql -u root -p
```
- Enter the password of database root password (DB_ROOT_PASSWORD)

Verify that database is not empty
```bash
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT *FROM wp_users;
SELECT COUNT(*) FROM wp_posts;
SELECT COUNT(*) FROM wp_users;
```






how to change the port
for nginx
443 to 8443
