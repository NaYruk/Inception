#!/bin/bash

# Quitte le script si CRASH
set -e

# Générer les certificats SSL s'ils n'existent pas
if [ ! -f /etc/nginx/ssl/mmilliot.crt ]; then
    echo "Génération des certificats SSL..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/mmilliot.key \
		-out /etc/nginx/ssl/mmilliot.crt \
		-subj "/C=FR/ST=Alsace/L=Mulhouse/O=42/CN=mmilliot.42.fr"
    echo "Certificats générés"
fi

# Tester la configuration nginx
echo "Vérification de la configuration..."
nginx -t

# Démarrer nginx
echo "Démarrage de Nginx..."
exec nginx -g 'daemon off;'

