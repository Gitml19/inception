#!/bin/bash
set -e

# Remplace la variable DOMAIN_NAME dans nginx.conf
sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

# Vérifie la configuration avant de démarrer
nginx -t

echo "Démarrage de NGINX..."
exec nginx -g "daemon off;"