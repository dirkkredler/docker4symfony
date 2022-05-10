SHELL := /bin/zsh

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_\-\.]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

autoload: 																## composer dump-autoload
	composer dump-autoload --optimize --classmap-authoritative
	./vendor/bin/psalm --clear-cache

env: 																	## composer dump-env
	composer dump-env dev

unittest: 																	## phpunit and panther tests
	export APP_ENV=test
	php ./vendor/bin/phpunit $(s) --testdox --coverage-html=coverage/

applicationtest: 																	## cypress e-2-e tests
	yarn cypress:run --spec cypress/integration/app_spec.js
	yarn cypress:open

analyse: 																	## phpstan and psalm static-code analysis s=<source>
	-./vendor/bin/psalm --show-info=true $(s)
	@echo "\n\n"
	-./vendor/bin/phpstan analyse $(s)

consume: 															## messenger consume
	#symfony run -d --watch=config,src,templates,vendor symfony console messenger:consume async failed
	bin/console messenger:consume async async_priority_low failed -vv

migrate: 																    ## make migration and migrate
	bin/console make:migration
	bin/console doctrine:migrations:migrate -n

clean-migration: 															## complete clean migration
	php8.0 bin/console doctrine:database:drop --force
	php8.0 bin/console doctrine:database:create
	php8.0 bin/console doctrine:cache:clear-metadata
	php8.0 bin/console doctrine:cache:clear-result
	php8.0 bin/console doctrine:cache:clear-query
	php8.0 bin/console c:c --no-warmup
	php8.0 bin/console c:c --env=prod --no-warmup
	-rm migrations/*.php
	php8.0 bin/console make:migration --env=dev
	php8.0 bin/console doctrine:migrations:migrate --env=dev
	php8.0 bin/console app:search-meeting --clear

build: 																## upgrade dependencies and build app
	composer update
	composer dump-autoload --optimize --classmap-authoritative
	composer dump-env prod
	yarn upgrade
	yarn install --force
	# adjust src/site/globals/site.variables to your needs
	npx gulp build --gulpfile=semantic/gulpfile.js 
	yarn build
	bin/console assets:install public
	bin/console c:c --no-warmup
	bin/console c:c --env=prod --no-warmup
	composer dump-env dev

clear-search-cache-and-index: 												## clear search cache and index
	bin/console app:search-meeting --clear

refactor: 																## refactor with the rules in rector.php
	vendor/bin/rector

.PHONY: help autload unittest applicationtest analysis consume migrate clean-migration build clear-search-and-index refactor
