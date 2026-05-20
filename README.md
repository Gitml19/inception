# inception

docker-compose
on utilise build et pas image car sinon ca utilise les images officielle de Docker Hub
build dans le compose et tout est lancer via docker compose up --build

image = template immuable
container = instance en cours d’exécution
build: construit l’image
up lance les containers
--build force la reconstruction des images si nécessaire

1. Le Makefile lance docker compose
2. docker compose lit le docker-compose.yml
3. Pour chaque service avec build:
Docker construit une image à partir du Dockerfile
4. Ensuite Docker crée et lance les containers à partir de ces images

build: ./requirements/mariadb
build on donne le contexte de build (le dossier), pas directement le fichier Dockerfile. Docker va automatiquement chercher ./requirements/nginx/Dockerfile

declare un network
networks:
  inception:
    driver: bridge
bridge = reseau priver par defaut

attacher les services au network
services:
 mariadb:
    build: ./requirements/mariadb
    networks:
      - inception

listen = 9000 -> PHP-FPM écoute sur :9000
ensuite il faut lui dire qui a le droit de parler a ce port/socket
listen.owner = www-data -> seul l'utilisateur www-data peut acceder
listen.group = www-data -> le groupe www-data aussi
www-data = utilisateur standard Linux deja prevu pour les serveurs web, utiliser pour nginc, apache, php-fpm

bind-address = 0.0.0.0 -> sert a autoriser les connexions depuis d’autres containers Docker
car par defaut mariadb ecoute sur 127.0.0.1 -> uniquement accessible depuis le même container, personne d’extérieur ne peut se connecter
or wordpress doit pouvoir faire connexion réseau vers MariaDB via le nom du service (mariadb)

1. NGINX (serveur web)

👉 Rôle : recevoir les requêtes HTTP/HTTPS et les envoyer à WordPress

📦 Outils nécessaires :
nginx
openssl (si SSL/TLS demandé)
fichiers .conf
🧰 Dans Dockerfile :
installation nginx
copie du nginx.conf
génération certificat SSL

2. MariaDB (base de données)

👉 Rôle : stocker les données WordPress

📦 Outils nécessaires :
mariadb-server
mariadb-client (optionnel mais utile)
🧰 Config importante :
mysqld config (bind-address)
script d’init SQL (création DB + user)

3. WordPress (PHP-FPM)

👉 Rôle : générer le site dynamique

📦 Outils nécessaires :
php-fpm
extensions PHP :
php-mysqli
php-json
php-curl
php-mbstring
wget ou curl (pour télécharger WordPress)
tar (décompression)
🧰 Config :
wp-config.php
www.conf (php-fpm)

apt-get install php php-fpm -> installe PHP (le langage) et PHP-FPM (le serveur qui exécute PHP) 
mais pas toutes les fonctionnalites Wordpress
php-mysqli -> connexion a Mariadb
php-curl ->télécharger APIs, plugins, updates
php-json ->communication moderne (API REST WordPress)
php-mbstring ->gestion UTF-8, langues, caractères spéciaux


1. Vue globale du projet

Tu construis essentiellement ceci :

Internet / navigateur
        ↓
      NGINX
        ↓
   WORDPRESS (PHP-FPM)
        ↓
     MARIADB

Chaque conteneur a un rôle précis :

Container	Rôle
nginx	reçoit les requêtes HTTPS
wordpress	exécute le PHP WordPress
mariadb	stocke les données

IMPORTANT :

nginx NE parle PAS directement à MariaDB
MariaDB ne connaît pas nginx
WordPress est le milieu entre les deux
2. Le vrai fonctionnement HTTP

Quand tu vas sur :

https://makoon.42.fr

voici ce qui se passe :

Étape A — Le navigateur contacte NGINX

Le port exposé :

ports:
  - "8443:443"

signifie :

machine hôte:8443 -> container nginx:443

Donc nginx est la porte d’entrée.

Étape B — NGINX reçoit une requête PHP

Exemple :

/index.php

nginx ne sait PAS exécuter du PHP.

Il transmet donc la requête à :

wordpress:9000

via FastCGI.

C’est pour ça que WordPress tourne avec php-fpm.

Étape C — WordPress a besoin des données

WordPress demande :

SELECT * FROM wp_users;

à MariaDB via le réseau Docker :

mariadb:3306
3. Le réseau Docker

Dans ton compose :

networks:
  - inception

Tous les containers rejoignent le même réseau privé.

Docker crée automatiquement un DNS interne.

Donc :

mariadb

devient une adresse IP interne.

C’est pour ça que WordPress peut utiliser :

WORDPRESS_DB_HOST=mariadb:3306


L’ordre le plus simple :

Étape 1 — MariaDB

Objectif :

le conteneur démarre
MariaDB écoute sur 3306
la base existe
l’utilisateur existe

Tant que ça ne marche pas :
NE PAS toucher WordPress.

Test :

docker exec -it mariadb mysql -u root -p

Puis :

SHOW DATABASES;
Étape 2 — WordPress + PHP-FPM

Objectif :

php-fpm tourne
WordPress est installé
WordPress se connecte à MariaDB

IMPORTANT :
à ce stade nginx n’est pas nécessaire.

Tu peux tester avec :

docker exec -it wordpress bash

Puis :

php-fpm7.4 -F

ou selon la version.

Le point critique ici :
le fichier wp-config.php.

Il doit contenir :

define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wpuser' );
define( 'DB_PASSWORD', 'wppassword' );
define( 'DB_HOST', 'mariadb:3306' );
Étape 3 — NGINX

Seulement maintenant.

NGINX :

sert les fichiers statiques
transmet le PHP à wordpress:9000
gère TLS/SSL

Exemple de config :

server {
    listen 443 ssl;
    server_name makoon.42.fr;

    ssl_certificate     /etc/nginx/ssl/inception.crt;
    ssl_certificate_key /etc/nginx/ssl/inception.key;

    root /var/www/html;
    index index.php;

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}

Le point clé :

fastcgi_pass wordpress:9000;

nginx parle au container wordpress via le réseau Docker.

5. Comprendre les volumes

Tu as :

wordpress_data:/var/www/html

Ce volume est partagé entre :

nginx
wordpress

Pourquoi ?

Parce que :

WordPress écrit les fichiers
nginx doit les lire

Sans volume partagé :
nginx ne verrait pas les fichiers WordPress.

6. Le vrai rôle des scripts init.sh

Beaucoup d’étudiants pensent :

"les scripts lancent Docker"

Non.

Docker lance le container.

Le script sert à :

installer/configurer le service
préparer l’environnement
puis lancer le processus principal

Exemple MariaDB :

init.sh
 ├─ initialise la DB
 ├─ crée users/database
 └─ lance mysqld

Exemple WordPress :

init.sh
 ├─ télécharge wordpress
 ├─ configure wp-config.php
 ├─ crée admin
 └─ lance php-fpm
7. La règle la plus importante de Docker

UN container = UN process principal.

Donc à la fin du script :

exec mysqld_safe

ou :

exec php-fpm7.4 -F

Le process doit rester au foreground.

Sinon le container s’arrête.

8. Pourquoi tes scripts semblent “cassés”

Parce qu’en réalité :

Docker
MariaDB
WordPress
php-fpm
nginx
volumes
réseau

interagissent tous.

Quand un maillon casse :
tout paraît incompréhensible.

Mais si tu testes :
1 service à la fois,
tout devient logique.

9. Méthode de debug recommandée

Toujours vérifier :

Les containers
docker ps
Les logs
docker logs mariadb
docker logs wordpress
docker logs nginx
Le réseau

Depuis wordpress :

ping mariadb
Les ports
netstat -tlnp


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
