#!/bin/bash

set -e

# Lire les secrets depuis les fichiers
MYSQL_PASSWORD=$(cat /run/secrets/mysql_user_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)

echo "Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u"${MYSQL_DB_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done

echo "MariaDB is up - continuing"

cd /var/www/html
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_DB_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    echo "Installing WordPress..."
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "Creating additional user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "WordPress installation completed!"
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
