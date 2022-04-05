#!/usr/bin/env bash
 
composer install
composer dump-autoload --optimize --classmap-authoritative
composer dump-env dev
yarn install
 
bin/console about

#bin/console doc:mig:mig --no-interaction
#bin/console doc:fix:load --no-interaction

# todo
# composer and yarn install
# user id with group 
# symfony cli

exec "$@"
