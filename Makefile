SHELL := /bin/bash

t ?= dev
s ?=
c ?=

# Executables (local)
DOCKER_COMP = docker-compose

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec web
DB_CONT = $(DOCKER_COMP) exec database

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
SYMFONY  = $(PHP_CONT) symfony console

# Misc
.DEFAULT_GOAL = help
.PHONY        = help build clean up start down logs sh mysql chown composer install update dump-autoload dump-env symfony cc doctrine migration migrate consume fixtures psalm psalm-cc test test-with-database-reset setup app yarn-build yarn-watch

help:
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## Docker
build: ## Builds the Docker image
	@$(DOCKER_COMP) build

clean: ## Builds a fresh Docker image
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) up --detach

start: build up ## Build and start the containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect with bash to the web (php and node with apache) container
	@$(PHP_CONT) bash

mysql: ## Connect with mysql client to the database container
	@$(DB_CONT) mysql

chown: ## Chown to the current host user
	@$(DOCKER_COMP) exec web chown -R $(shell id -u):$(shell id -g) .

## Composer
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

install: ## Install vendors according to the current composer.lock file
install: c=install
install: composer

update: ## Update vendors according to the current composer.json file
update: c=update
update: composer

dump-autoload: ## Run `composer dump-autoload`
	@$(COMPOSER) dump-autoload --optimize --classmap-authoritative

dump-env: ## Run `composer dump-env` with the given environment; pass the "t=" parameter like "t=dev" (default), "t=test" or "t=prod" to specifiy an environment
	@$(COMPOSER) dump-env $(t)

## Symfony
symfony: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: `make symfony c=about`
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: ## Clear the cache
	@$(SYMFONY) c:c

doctrine: ## Perform `symfony console doctrine:<command>` use eg. `make doctrine c="database:create"`
	@$(SYMFONY) doctrine:$(c)

migration: ## Make a migration 
	@$(SYMFONY) make:migration

migrate: ## Perform the migration 
	@$(SYMFONY) doctrine:migrations:migrate

consume: ## Consume messenges 
	@$(SYMFONY) messenger:consume async async_priority_low failed -vv

## Test

psalm: ## Run static code analysis, use "s=<file or directory>" to analyse only the folder or file 
	@$(PHP_CONT) ./vendor/bin/psalm --show-info=true $(s)

psalm-cc: ## Clear static code analysis cache
	@$(PHP_CONT) ./vendor/bin/psalm --clear-cache

test: ## Run tests and create code coverage information, use "s=<file or directory>" to test only the folder or file
	@$(COMPOSER) dump-env test
	@$(PHP_CONT) ./vendor/bin/phpunit -d memory_limit=256M $(s) --testdox --coverage-html=coverage/
	@$(COMPOSER) dump-env dev

test-with-database-reset: ## Run tests, reset the database and create code coverage information, use "s=<file or directory>" to test only the folder or file
	@$(COMPOSER) dump-env test
	@$(SYMFONY) doctrine:database:drop --force --if-exists
	@$(SYMFONY) doctrine:database:create
	@$(SYMFONY) doctrine:schema:create
	@$(PHP_CONT) ./vendor/bin/phpunit -d memory_limit=256M $(s) --testdox --coverage-html=coverage/
	@$(COMPOSER) dump-env dev

fixtures: ## Load the demo or test fixtures 
	@$(SYMFONY) doctrine:fixtures:load --group=test -n

## App
setup: ## Setup the database for the current environment
	@$(SYMFONY) doctrine:database:drop --force --if-exists
	@$(SYMFONY) doctrine:database:create
	@$(SYMFONY) doctrine:schema:create
	@$(SYMFONY) doctrine:fixtures:load --group=setup -n

app: ## Update dependencies and build the app for the given environment; pass the "t=" parameter like "t=dev" (default), "t=test" or "t=prod" to specifiy an environment
	@$(COMPOSER) update
	@$(COMPOSER) dump-autoload --optimize --classmap-authoritative
	@$(COMPOSER) dump-env $(t)
	@$(SYMFONY) c:c
	@$(SYMFONY) assets:install
	@$(PHP_CONT) yarn install --force
	@$(PHP_CONT) yarn upgrade
	@$(PHP_CONT) npx gulp build --gulpfile=semantic/gulpfile.js
	@$(PHP_CONT) yarn build

# to initially install fomantic-ui use:
# `yarn add fomantic-ui --ignore-scripts`
# `yarn --cwd node_modules/fomantic-ui run install`
#
# adjust src/site/globals/site.variables to your needs

yarn-build: ## Build the frontend
	@$(PHP_CONT) yarn build

yarn-watch: ## Watch any changes and build the frontend
	@$(PHP_CONT) yarn watch

# vim: syntax=make
