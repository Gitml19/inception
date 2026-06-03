#!/bin/bash

set -e

# chemin ou wordpress sera installer
WP_PATH="/var/www/wordpress"

# cree le dossier s'il existe pas et donne les droits a l'utilisateur
mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH"

cd /tmp

# Télécharge WordPress seulement si pas déjà installé
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  wp core download --allow-root --path=$WP_PATH

# cree la config DB  
  wp config create --allow-root \
    --dbname=$DB_NAME \
    --dbuser=$DB_USER \
    --dbpass="$(cat /run/secrets/db_password)" \
    --dbhost="mariadb:3306" \
    --path=$WP_PATH
fi

echo "Waiting for MariaDB..."

until mysqladmin ping -h mariadb --silent; do
    sleep 2
done

echo "MariaDB is ready!"

# verifie si WP est installer en DB pour configurer WP et creer des utilisateurs
if ! wp core is-installed --path="$WP_PATH" --allow-root 2>/dev/null; then

  echo "Installing WordPress (WP-CLI)..."

  wp core install \
      --path="$WP_PATH" \
      --url="https://${DOMAIN_NAME}" \
      --title="${WP_TITLE}" \
      --admin_user="${WP_ADMIN_USER}" \
      --admin_password="$(cat /run/secrets/wp_admin_password)" \
      --admin_email="${WP_ADMIN_EMAIL}" \
      --skip-email \
      --allow-root
    
  echo "Creating secondary user..."

  wp user create \
      "${WP_USER}" "${WP_USER_EMAIL}" \
      --role=author \
      --user_pass="$(cat /run/secrets/wp_user_password)" \
      --path="$WP_PATH" \
      --allow-root

fi

echo "Starting php-fpm..."

exec php-fpm8.2 -F