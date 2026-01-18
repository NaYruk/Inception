#!/bin/bash

# Préparation des permissions
mkdir -p /run/mysqld /var/log/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql /var/log/mysql

# Vérifier si la base est déjà configurée (fichier marqueur)
if [ ! -f "/var/lib/mysql/.db_configured" ]; then
    echo "Première initialisation de MariaDB..."

    # Initialiser le répertoire de données MariaDB
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    echo "Démarrage temporaire de MariaDB..."
    mariadbd --user=mysql --skip-networking &
    TEMP_PID=$!

    # Attente que MariaDB soit prêt
    until mariadb -uroot -e "SELECT 1" &>/dev/null; do
        sleep 1
    done

    echo "Configuration de la base de données..."

    # Lire les secrets depuis les fichiers
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
    MYSQL_USER_PASSWORD=$(cat /run/secrets/mysql_user_password)
    
    mariadb -uroot << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Créer un fichier marqueur
    touch /var/lib/mysql/.db_configured

    echo "Arrêt du serveur temporaire..."
    mariadb-admin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
else
    echo "Base de données déjà initialisée, skip setup."
fi

echo "Démarrage final de MariaDB..."
exec mariadbd --user=mysql
