#!/bin/bash

set -e

# Remplace la variable DOMAIN_NAME dans nginx.conf
# s(pour substitute)/ancien/nouveau/g(pour global = tte les occurences)
sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

# Vérifie la configuration avant de démarrer : synthaxe ok et fichiers de config valides (-t pour test config)
nginx -t

echo "Démarrage de NGINX..."
exec nginx -g "daemon off;"