FROM debian:bookworm

RUN apt update && apt install -y \
	php php-fpm php-mysql php-cli \
	curl mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

# Créer le répertoire WordPress et définir les permissions
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Copier la configuration PHP-FPM
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Installer WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

COPY tools/wp-cli.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-cli.sh

CMD ["wp-cli.sh"]