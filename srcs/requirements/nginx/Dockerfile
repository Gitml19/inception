FROM debian:bookworm

# nginx = serveur web qui va recevoir les requetes HTTP/HTTPS
# openssl = sert a generer un certificat SSL
RUN apt-get update && apt-get install -y \
	nginx \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

# pour creer le dossier qui permet de stocker le certificat SSL et la clef pour une connexion securisee
RUN mkdir -p /etc/nginx/ssl

# commande req pour creer des certificats auto-signer
# -x509 pour preciser le type du certificat
# option -nodes = clef privee sans mot de passe
# option -out et -keyout pour indiquer a openssl ou l'on souhaite stocker le certificat et la clef de notre SSL
# ces 2 certificats vont demander des infos pour le certificat et avec -subj on peut les preremplir
RUN openssl req -x509 -nodes \
	-out /etc/nginx/ssl/nginx.crt \
	-keyout /etc/nginx/ssl/nginx.key \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}" \
	-days 365

# remplace la config par defaut de nginx
COPY conf/default.conf /etc/nginx/conf.d/default.conf

COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init.sh"]