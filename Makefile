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
.PHONY        = help build clean up start down logs sh mysql chown composer vendor autoload env sf cc setup fixtures migration consume analyse test analyse app 

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
autoload: c=dump-autoload --optimize --classmap-authoritative
autoload: composer

env: ## composer dump-env given environment
env: c=dump-env $(t)
env: composer

## Symfony
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: c=c:c ## Clear the cache
cc: sf

### App
setup: ## setup database for the given environment
setup: env
setup: c=doctrine:database:drop --force
setup: sf
setup: c=doctrine:database:create
setup: sf
setup: c=doctrine:schema:create
setup: sf

fixtures: ## doctrine load fixtures
fixtures: c=doctrine:fixtures:load -n
fixtures: sf

migration: ## doctrine make migration and migrate
migration: c=make:migration
migration: sf

consume: ## messenger consume
consume: c=messenger:consume async async_priority_low failed -vv
consume: sf

analyse: ## psalm static code analysis 
	@$(PHP_CONT) ./vendor/bin/psalm --show-info=true $(s)

test: ## phpunit with code-coverage
test: t=test
test: env
	@$(PHP_CONT) ./vendor/bin/phpunit -d memory_limit=256M $(s) --testdox --coverage-html=coverage/
test: t=dev
test: env

app: ## update dependencies and build the app 																
app: c=update
app: composer
app: c=dump-autoload --optimize --classmap-authoritative
app: composer
app: c=dump-env $(t)
app: composer
#app: c=assets:install
#app: sf
app: cc
	@$(PHP_CONT) yarn install --force
	@$(PHP_CONT) yarn upgrade
#	# to initially install fomantic-ui use:
#	# `yarn add fomantic-ui --ignore-scripts`
#	# `yarn --cwd node_modules/fomantic-ui run install`
#	#
#	# adjust src/site/globals/site.variables to your needs
	@$(PHP_CONT) npx gulp build --gulpfile=semantic/gulpfile.js 
	@$(PHP_CONT) yarn build
