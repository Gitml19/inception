#!/bin/bash

# si une commande echoue, arrete immediatement le script
set -e

# cree le dossier socket si necessaire
mkdir -p /run/mysqld
# donne les droits a l'utilisateur mysql
chown -R mysql:mysql /run/mysqld

# si la base n'est pas encore initialiser car le  dossier /var/lib/mysql/mysql existe seulement apres l'initialisation systeme
# sans ca, la DB sera recreer a chaque demarrage et on perd les donnees
# if [ ! -d "/var/lib/mysql/mysql" ]; then
    # echo "je vain me initializer ATTENTION"
    # Initialise les fichiers système MariaDB, fabrique la base vide
    # cree les tables systeme, les fichiers internes mariadb, les permissions initiales
    # > /dev/null = cache la sortie, on peut l'enlever pour debug
    # mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Démarre MariaDB temporairement pour configurer
    # mariadb demarre sans reseau, sans daemon complet, juste pour executer du sql, mode special d'initalisation
    # permet de creer des users, DB et securiser root avant le vrai demarrage
    #    --bootstrap : permet d'envoyer des requetes SQL a mariadb sans qu'il soit completement demarrer, uniquement pour l'initialisation
    # mysqld --user=mysql --bootstrap << EOF

# -- Supprime les utilisateurs anonymes et la base test car mariadb cree parfois des comptes anonymes et une DB test
# DELETE FROM mysql.user WHERE User='';
# DROP DATABASE IF EXISTS test;
# cat > /tmp/init.sql <<EOF
# -- Crée la base WordPress
# CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

# -- Crée l'utilisateur WordPress
# -- % = connexion depuis n'importe quelle IP et comme wordpress vient d'un autre conteneur, c'est necessaire
# CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
# -- donne acces a wordpress sur sa DB
# GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

# -- Sécurise le root car sinon root peut ne pas avoir de mot de passe
# ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

# -- recharge les permissions MySQL
# FLUSH PRIVILEGES;
# EOF

# # Lance MariaDB en foreground (PID 1)
# exec mysqld --user=mysql --init-file=/tmp/init.sql


# # Stop le script si une commande échoue
# set -e

# # Crée le dossier du socket MariaDB
# mkdir -p /run/mysqld

# # Donne les permissions à mysql
# chown -R mysql:mysql /run/mysqld

# # Initialise MariaDB seulement si la DB n'existe pas déjà
# if [ ! -d "/var/lib/mysql/mysql" ]; then

#     echo "Initialisation de MariaDB..."

#     # Crée les fichiers système MariaDB
#     mysql_install_db --user=mysql --datadir=/var/lib/mysql

#     # Lance MariaDB temporairement
#     mysqld_safe --datadir=/var/lib/mysql &

#     # Attend que MariaDB soit prête
#     while ! mysqladmin ping --silent; do
#         sleep 1
#     done

#     echo "Configuration de MariaDB..."

#     # Configure la DB et les utilisateurs
#     mariadb -e "
#         DELETE FROM mysql.user WHERE User='';

#         DROP DATABASE IF EXISTS test;

#         CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

#         CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

#         GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

#         ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

#         FLUSH PRIVILEGES;
#     "

#     # Stop le serveur temporaire
#     mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

#     echo "MariaDB configurée."
# fi

# # Lance MariaDB au foreground
# exec mysqld --user=mysql