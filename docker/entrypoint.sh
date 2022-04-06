#!/bin/bash

source ~/.bashrc
 
composer install
composer dump-autoload --optimize --classmap-authoritative
composer dump-env dev

yarn install

#symfony console doctrine:migrations:migrate --no-interaction
#symfony console doctrinre:fixtures:load --no-interaction

# todo
# add makefile with --no-cache:
# build: ## Builds the Docker images
#    docker-compose build --no-cache

exec "$@"
