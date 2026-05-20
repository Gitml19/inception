#!/bin/sh

set -e 

# cree le dossier socket si necessaire
mkdir -p /run/mysqld
# donne les droits a l'utilisateur mysql
chown -R mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "initialization de la db"
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    #init file pour le sql
    cat > /tmp/init.sql <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
-- Crée l'utilisateur WordPress
-- % = connexion depuis n'importe quelle IP et comme wordpress vient d'un autre conteneur, c'est necessaire
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
-- donne acces a wordpress sur sa DB
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
-- Sécurise le root car sinon root peut ne pas avoir de mot de passe
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
-- recharge les permissions MySQL
FLUSH PRIVILEGES;
EOF
    exec mysqld --user=mysql --init-file=/tmp/init.sql
else
    exec mysqld --user=mysql
fi