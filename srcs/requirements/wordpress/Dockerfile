FROM debian:bullseye

# php-fpm : server PHP fastcdgi car nginx ne sait pas executer du php directement, donc permet a php de parler avec mariadb/mysql
# php-curl : permet a php de faire des requetes HTTP, telecharges des ressources
# php-gd : gestion des images
# php-mbstring : pour les caracteres speciaux
# curl pour telecharger des fichiers
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-json \
    php7.4-curl \
    php7.4-mbstring \
    wget \
    curl \
    tar \
    netcat-openbsd \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# chemin a verifier
# modifie www.conf pour que php-fpm ecoute sur le reseau docker donc php ecoute sur 0.0.0.0:9000
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

COPY tools/setup.sh /usr/local/bin/setup.sh

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar --output-dir /bin/

RUN chmod +x /bin/wp-cli.phar && mv /bin/wp-cli.phar /bin/wp

RUN chmod +x /usr/local/bin/setup.sh

RUN mkdir -p /run/php

# pas obligatoire, juste pour info pour dire que ce conteneur utilise le port 9000
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]