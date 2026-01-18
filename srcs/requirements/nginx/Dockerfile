# Image de base Debian Bookworm
FROM debian:bookworm

# Installation de Nginx et nettoyage du cache apt
RUN apt-get update && \
	apt-get install -y \
		nginx \
		openssl \
		curl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Copier la configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copier le script
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Créer le dossier SSL
RUN mkdir -p /etc/nginx/ssl

EXPOSE 443

CMD ["/usr/local/bin/entrypoint.sh"]