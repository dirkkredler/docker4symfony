# Symfony and docker

This is my docker setup i currently use in my symfony projects,
heavily inspired by https://github.com/dunglas/symfony-docker

## Installation

Add

    "repositories": [
        {
            "type": "vcs",
            "url": "https://github.com/dirkkredler/docker4symfony"
        }
    ],

to your `composer.json` and add an entry under the `require-dev` key: `"dirkkredler/docker4symfony": "dev-main"`

    $ composer update
    $ cp -r vendor/dirkkredler/docker4symfony/docker .
    $ cp vendor/dirkkredler/docker4symfony/Dockerfile .
    $ cp vendor/dirkkredler/docker4symfony/docker-compose.yaml .
    $ cp vendor/dirkkredler/docker4symfony/.dockerignore .

and add the directories to your `.gitignore` file:

    $ echo "/profile\n/coverage\n" >> .gitignore

for easier usage you should use the `make` command with the enclosed Makefile:

    $ cp vendor/dirkkredler/docker4symfony/Makefile .

please adjust it to your needs.

## Notes

Symfony specific `.env.local` settings should be used like this:

-   `MAILER_DSN='smtp://mail:1025?verify_peer=false'`
-   `DATABASE_URL='mysql://root:@database:3306/app?serverVersion=5.7'`
-   `APP_MAIL='dirk@localhost.test'`
-   `APP_URI='https://localhost'`

Since we use apache, do not forget to `composer require symfony/apache-pack` to add support for the webserver within
your symfony-app and feel free to add some caching to your static assets:

    $ vi public/.htaccess
    ...
    <filesMatch ".(css|js|jpg|jpeg|png|gif|ico|woff2)$">
    	Header set Cache-Control "max-age=31536000, public"
    </filesMatch>
    ...

Remember to update your `config/doctrine.yaml` server version:

    $ vi config/doctrine.yaml
    doctrine:
        dbal:
            url: "%env(resolve:DATABASE_URL)%"
            server_version: "5.7"
    ...

Remember to use the `make symfony` or `make doctrine` or the `docker-compose` equivalents for all commands, which need the correct environment
to access docker containers or which uses services provided by docker.

## Usage

    $ cd <your-project>
    $ make clean # or make build to build the containers
    $ make up # to start the containers

or

    $ make start # to build and start the containers
    $ make sh # to connect with the web container
    $ make mysql # to use the mysql-client with the database container

Please check the `Makefile` for additional shortcuts; anyway you can use `docker-compose` instead of the `make` command:

    $ docker-compose build --pull --no-cache
    $ docker-compose up --detach
    $ docker-compose down --remove-orphans
    $ docker-compose exec web bash
    $ docker-compose exec database mysql

and so on.

You can also use your locally installed `php`, `composer` or `symfony` binary, but you should use versions which match the installed binaries in the containers.

The containers use the standard ports, please adjust the `docker-compose.yaml` file to your needs.

The webserver https://localhost, the mailhog http://localhost:8025 and finally your
your locally installed mysql-client: `mysql --host 127.0.0.1 -u root` should work now.

## Recommended

Add the static analysis tool `psalm` to your installation and enable the symfony psalm plugin:

    $ composer require --dev psalm/plugin-symfony
    $ vendor/bin/psalm --init
    $ vendor/bin/psalm-plugin enable psalm/plugin-symfony
    $ make psalm

Add `phpunit` to your project:

    $ composer require --dev symfony/test-pack
    $ php bin/phpunit
    $ make test

## WIP

### TODO

-   add an installer script
-   use docker-compose profile with different webserver and database engines
-   multi-build: add production profile / target with all builded artifacts, w/o anything uneeded for production
-   add nginx, elasticsearch
