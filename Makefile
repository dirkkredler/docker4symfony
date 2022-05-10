SHELL := /bin/bash

t ?= dev
s ?=

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
.PHONY        = help build clean up start down logs sh mysql chown composer vendor autoload env sf cc setup fixtures migration migrate consume analyse test analyse analyse-clear app fbuild

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

vendor: ## Install vendors according to the current composer.lock file
vendor: c=install
vendor: composer

autoload: ## composer dump-autoload
	@$(COMPOSER) dump-autoload --optimize --classmap-authoritative

env: ## composer dump-env given environment
	@$(COMPOSER) dump-env $(t)

## Symfony
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: ## Clear the cache
	@$(SYMFONY) c:c

### App
setup: ## setup database for the given environment
	@$(SYMFONY) doctrine:database:drop --force --if-exists
	@$(SYMFONY) doctrine:database:create
	@$(SYMFONY) doctrine:schema:create
	@$(SYMFONY) doctrine:fixtures:load --group=setup -n

fixtures: ## doctrine load fixtures
	@$(SYMFONY) doctrine:fixtures:load --group=test -n

migration: ## doctrine make migration
	@$(SYMFONY) make:migration

migrate: ## doctrine make migrate
	@$(SYMFONY) doctrine:migrations:migrate

consume: ## messenger consume
	@$(SYMFONY) messenger:consume async async_priority_low failed -vv

analyse: ## psalm static code analysis
	@$(PHP_CONT) ./vendor/bin/psalm --show-info=true $(s)
analyse-clear: ## psalm clear static analysis cache
	@$(PHP_CONT) ./vendor/bin/psalm --clear-cache

test: ## phpunit with code-coverage
	@$(COMPOSER) dump-env test
	@$(PHP_CONT) ./vendor/bin/phpunit -d memory_limit=256M $(s) --testdox --coverage-html=coverage/
	@$(COMPOSER) dump-env dev

app: ## update dependencies and build the app
	@$(COMPOSER) update
	@$(COMPOSER) dump-autoload --optimize --classmap-authoritative
	@$(COMPOSER) dump-env $(t)
	@$(SYMFONY) c:c
	@$(SYMFONY) assets:install
	@$(PHP_CONT) yarn install --force
	@$(PHP_CONT) yarn upgrade
#	# to initially install fomantic-ui use:
#	# `yarn add fomantic-ui --ignore-scripts`
#	# `yarn --cwd node_modules/fomantic-ui run install`
#	#
#	# adjust src/site/globals/site.variables to your needs
	@$(PHP_CONT) npx gulp build --gulpfile=semantic/gulpfile.js
	@$(PHP_CONT) yarn build

fbuild: ## build the frontend
	@$(PHP_CONT) yarn build
