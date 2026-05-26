FROM debian:bookworm

# apt-get update : maj des paquets disponibles
# apt-get update mariadb-server : installe le serveur mariadb
# rm -rf /var/lib/apt/lists/* :  supprime les fichiers temporaires telecharges par apt (utile pour reduire la taille de l'image)
# rm -rf /var/lib/mysql/* : supprime les anciennes donnees MariaDB car il y a des fichiers pre initialiser et sinon on peut pas init nous meme
RUN apt-get update && apt-get install -y \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# remplace la config par la mienne, pour forcer a 0.0.0.0  (ecoute sur ttes les interfaces reseau) au lieu de localhost (127.0.0.1 par defaut)
# sinon wordpress ne peut pas joindre mariadb
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# copie le script d'init dans le conteneur /usr/local/bin/init.sh
# le script initialise la DB, cree les users, cree la base Wordpress et demarre MariaDB
COPY tools/init.sh /usr/local/bin/init.sh

# donne les permissions d'execution pour le script
RUN chmod +x /usr/local/bin/init.sh

# port par defaut de mariadb
EXPOSE 3306

# execute a chaque demarrage du conteneur
ENTRYPOINT ["/usr/local/bin/init.sh"]