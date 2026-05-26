# User documentation - Inception project

## Services provided

This stack runs a Wordpress website accessible via HTTS, backed by a MariaDB database.
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
Click 'Advanced' then 'Proceed' to continue.

## Credentials

All credentials are stored in:
- `srcs/.env` : usernames, database name, domain
- `secrets/db_password.txt` : database user password
- `secrets/db_root_password.txt` : database root password
- `secrets/credentials.txt` : Wordpress admin credentials

**Never commit these files to Git.**

## Check that services are running

```bash
make status             # See all running containers and their status
make logs               # Follow live logs
make logs -f <service>  # Follow logs for one specific service i.e. make logs -f nginx
```

All three containers should show status `Up`. If one is restarting repeatedly, check its logs for errors.