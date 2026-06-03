FROM debian:bookworm

# php-fpm : server PHP fastcdgi car nginx ne sait pas executer du php directement, donc permet a php de parler avec mariadb/mysql
# php-curl : permet a php de faire des requetes HTTP, telecharges des ressources
# php-mbstring : pour les caracteres speciaux
# php8.2-mysql : connexion a mariadb
# php8.2-curl : requetes HTTP depuis PHP
# curl ou wget : pour telecharger des fichiers
# netcat : pour tester les connexions reseau
# mariadb-client : permet a PHP ou scripts de parler a mariadb
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-mbstring \
    wget \
    curl \
    tar \
    netcat-openbsd \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# modifie www.conf pour que php-fpm ecoute sur le reseau docker donc php ecoute sur 0.0.0.0:9000 au lieu de 127.0.0.1:9000 car nginx est dans un autre conteneur
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# copie le script qui permet de telecharger wordpress, config wp-config.php, connecter mariadb et lancer php-fpm
COPY tools/setup.sh /usr/local/bin/setup.sh

# installe wp-cli qui sert a installer wordpress automatiquement, creer unsers admin et config site sans navigateur
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --output-dir /bin/

# rend le fichier executable et le renomme en wp
RUN chmod +x /bin/wp-cli.phar && mv /bin/wp-cli.phar /bin/wp

# rend le script executable
RUN chmod +x /usr/local/bin/setup.sh

# creation dossier runtime php car php-fpm a besoin de ce dossier pour socket et pid file
RUN mkdir -p /run/php

# pas obligatoire, juste pour info pour dire que ce conteneur utilise le port 9000
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]