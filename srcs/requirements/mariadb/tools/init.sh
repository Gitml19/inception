#!/bin/sh

set -e
# = si une commande echoue, le script s'arrete immediatement (pour pas que mariadb demarre dans un etat casser)

# recupere les secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# cree le dossier socket si necessaire
mkdir -p /run/mysqld
# le process mariadb tourne avec l'utilisateur mysql
# chmod = change le proprietaire d'un fichier/dossier, -R = applique a tout le dossier + son contenu, mysql:mysql = proprietaire:groupe
# donc donne les droits a l'utilisateur mysql pour avoir acces au dossier socket
chown -R mysql:mysql /run/mysqld

# si le dossier n'existe pas, mariadb n'a jamais ete initialiser
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "initialization de la db"
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    # creation du fichier sql
    cat > /tmp/init.sql <<EOF
-- Crée la base WordPress
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;

-- Crée l'utilisateur WordPress
-- % = connexion depuis n'importe quelle IP et comme wordpress vient d'un autre conteneur, c'est necessaire
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

-- donne acces a wordpress sur sa DB
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';

-- Sécurise le root car sinon root peut ne pas avoir de mot de passe
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
-- recharge les permissions MySQL
FLUSH PRIVILEGES;
EOF

# exec remplace le shell par mysqld et fait de mysqld le process PID1, cela permet de bien envoyer les signaux pour stop, sinon mariadb devient un process enfant
# demarrage mariadb avec init-file
    exec mysqld --user=mysql --init-file=/tmp/init.sql
else
# si existe deja, pas de reinitialisation, pas de recreation users et de sql, demarre juste MariaDB
    exec mysqld --user=mysql
fi