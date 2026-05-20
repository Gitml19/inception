NAME        = inception
COMPOSE     = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

all: up

up:
# 	cree les dossiers de volumes
# 	-p : cree les dossiees meme si les parents n'existent parents
# 	@ : emepeche make d'afficher la commande avant de l'executer
	@mkdir -p /home/$(shell whoami)/data/wordpress
	@mkdir -p /home/$(shell whoami)/data/mariadb
# 	up: demarre les conteneurs
# 	-d : mode detacher (background)
# 	--build : rebuild les images avant demarrage
	$(COMPOSE) up --build

# arrete et supprime les conteneurs, reseaux..., mais volumes et images persistent
down:
	$(COMPOSE) down

# arrete les conteneurs sans les supprimer donc peut etre relancer avec start
stop:
	$(COMPOSE) stop

# redemarre les conteneurs deja existants
start:
	$(COMPOSE) start

# redemarre tous les services
restart:
	$(COMPOSE) restart

# affiche l'etat des conteneurs
status:
	$(COMPOSE) ps

# affiche les logs en temps reel
# -f = follow
logs:
	$(COMPOSE) logs -f

# supprime conteneurs, volumes et reseaux
# avant de clean, make execute down et supprime les volumes docker
# docker volume ls -q = liste uniquement les ID/noms des volumes (mariadb_data, wordpress_data)
# $$ car dans un makefile, $ est reserver aux variables Make donc pour envoyer un vrai $ au shell, il faut ecrire $$
# 2>/dev/null = cache les erreurs
# || true = empeche make d'echouer si aucune ressource existe

# clean: down
clean:
	$(COMPOSE) down -v --remove-orphans
# 	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
# 	docker network rm $$(docker network ls -q) 2>/dev/null || true

# docker system prune -af = supprime les images inutilisees, cache, conteneurs stoppes, reseaux inutilises
# -a : tout supprimer
# -f = sans confirmation
# sudo rm -rf /home/$(shell whoami)/data = supprime les dossiers locaux
fclean: clean
	docker system prune -af
	sudo rm -rf /home/$(shell whoami)/data

re: fclean all

.PHONY: all up down stop start restart status logs clean fclean re
