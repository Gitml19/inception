echo "Waiting for MariaDB"

while ! mysqladmin ping -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} --silent; do
	sleep 2
done

echo "MariaDB is ready"

wp config create \
	--dbname=$MYSQL_DATABASE \
	--dbuser=$MYSQL_USER \
	--dbpass=$MYSQL_PASSWORD \
	--dbhost=mariadb:3306 \
	--allow-root

wp core install \
	--url=$DOMAIN_NAME \
	--title="Inception" \
	--admin_user=$WP_ADMIN_USER \
	--admin_password=$WP_ADMIN_PASSWORD \
	--admin_email=$WP_ADMIN_EMAIL \
	--skip-email \
	--allow-root

php-fpm -F

#sleep 10

#wp config create \
#	--dbname=$MYSQL_DATABASE \
#	--dbuser=$MYSQL_USER \
#	--dbpass=$MYSQL_PASSWORD \
#	--dbhost=mariadb:3306 \
#	--allow-root

#wp core install \
#	--url=$DOMAIN_NAME \
#	--title="Inception" \
#	--admin_user=$WP_ADMIN_USER \
#	--admin_password=$WP_ADMIN_PASSWORD \
#	--admin_email=$WP_ADMIN_EMAIL \
#	--skip-email \
#	--allow-root

#php-fpm -F

sleep 10

cd /var/www/wordpress

if [ ! -f wp-config.php ]; then

	cp wp-config-sample.php wp-config.php

	sed -i "s/database_name_here/$MYSQL_DATABASE/g" wp-config.php
	sed -i "s/username_here/$MYSQL_USER/g" wp-config.php
	sed -i "s/password_here/$MYSQL_PASSWORD/g" wp-config.php
	sed -i "s/localhost/$MYSQL_HOST/g" wp-config.php

fi

php-fpm7.4 -F