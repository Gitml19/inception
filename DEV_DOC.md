# Developer documentation - Inception project

## Prerequisites

- Virtual machine with Debian Bullseyes (or similar)
- Docker Engine installed: https://docs.docker.com/engine/install/debian/
- Docker Compose plugin installed
- `make` available
- `sudo` rights on the VM

## Environment setup from scratch


## Useful container management commands


## Data persistence

| Data              | Volume name    | Host path                    |
|-------------------|----------------|------------------------------|
| MariaDB database  | `srcs_mariadb` | `/home/login/data/mariadb`   |
| WordPress files   | `srcs_wordpress`| `/home/login/data/wordpress` |

Data survives `make down` and `make stop`.
Only `make fclean` or `make clean` removes it.

## Project structure
