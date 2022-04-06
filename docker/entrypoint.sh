#!/bin/bash

source ~/.bashrc
 
composer install
composer dump-autoload --optimize --classmap-authoritative
composer dump-env dev

yarn install

#symfony console doctrine:migrations:migrate --no-interaction
#symfony console doctrine:fixtures:load --no-interaction

chown 1000:1000 . -R

exec "$@"
