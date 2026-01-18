DOCKER_COMPOSE_PATH = ./srcs/docker-compose.yml
DATA_DIR = $(HOME)/data

# Fait les 4 etapes de lancement d'un coup
all: setup build run logs

# Setup tout le necessaire pour le lancement du build Etape 1
setup:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Dossiers de volumes créés dans $(DATA_DIR)"
	@if ! grep -q "127.0.0.1.*mmilliot.42.fr" /etc/hosts; then \
		echo "127.0.0.1   mmilliot.42.fr" | sudo tee -a /etc/hosts > /dev/null; \
		echo "Entrée /etc/hosts ajoutée pour mmilliot.42.fr"; \
	else \
		echo "Entrée /etc/hosts déjà présente pour mmilliot.42.fr"; \
	fi

# Build le docker-compose Etape 2
build:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) build

# Run le docker-compose Etape 3
run:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) up -d

# Montre les logs Etape 4
logs:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) logs -f



# Arrête et supprime les conteneurs
down:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) down

# Arrête et supprime les conteneurs + images
down_images:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) down -v --rmi all

# Nettoyage complet
fclean:
	@docker-compose -f $(DOCKER_COMPOSE_PATH) down -v --rmi all
	@sudo rm -rf $(DATA_DIR)
	@docker system prune -af --volumes

# Reconstruction complète
re: fclean all
