# Symfony and docker

## Installation

$ cp Dockerfile <your-project>
$ cp -r docker <your-project>
$ cp docker-compose.yaml <your-project>
$ cp .dockerignore <your-project>

if you would like to use the xdebug-profiler and -coverage,
create the corresponding directories:

$ mkdir <your-project>/profile
$ mkdir <your-project>/coverage

and at there to your `.gitignore` file:

$ echo "/profile\n/coverage\n" >> <your-project>/.gitignore

for easier usage you can use the `make` command with the enclosed Makefile:

$ cp Makefile <your-project>

please adjust it to your needs.

## Notes

Symfony specific `.env.local` settings should be used like this:

MAILER_DSN='smtp://mail:1025?verify_peer=false'
DATABASE_URL='mysql://root:@database:3306/app?serverVersion=5.7'
APP_MAIL='dirk@localhost.test'
APP_URI='https://localhost'

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

The containers use the standard ports, please adjust the `docker-compose.yaml` file to your needs.

https://localhost # webserver
http://localhost:8025 # mailhog
mysql --host 127.0.0.1 -u root

## WIP

### TODO

-   add an installer script
-   update Makefile with migration, tests and fixtures etc.
-   use docker-compose profile with different webserver and database engines
-   add production profile / target with all builded artifacts, w/o anything uneeded for production
-   https://symfony.com/doc/current/deployment.html#how-to-deploy-a-symfony-application
