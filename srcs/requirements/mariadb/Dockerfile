# Image de base Debian Bookworm
FROM debian:bookworm

# Installation de MariaDB et nettoyage du cache apt
RUN apt-get update && \ 
	apt-get install -y mariadb-server && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Copier la configuration personnalisée
COPY conf/99-custom.cnf /etc/mysql/mariadb.conf.d/99-custom.cnf

# Copier le script d'initialisation
COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

# Exposer le port MariaDB
EXPOSE 3306

VOLUME [ "/var/lib/mysql" ]

# Démarrer MariaDB via le script
CMD ["/usr/local/bin/init.sh"]