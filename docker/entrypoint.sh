#!/bin/bash

composer install
composer dump-autoload --optimize --classmap-authoritative
composer dump-env dev

yarn install

#symfony console doctrine:migrations:migrate --no-interaction
#symfony console doctrine:fixtures:load --no-interaction

chown $UID:$GID * -R

exec "$@"
