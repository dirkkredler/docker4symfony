FROM php:8.2-apache AS base

# USER to change the application data in the container
ARG UNAME=dev
ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID -o $UNAME \
  && useradd -m -u $UID -g $GID -G www-data -o -s /bin/bash $UNAME

ENV UID=$UID
ENV GID=$GID

# NODE
ARG NODE_VERSION=18.12.1
ARG NODE_ARCH=linux-x64
ARG NODE_PACKAGE=node-v$NODE_VERSION-$NODE_ARCH
ARG NODE_HOME=/opt/$NODE_PACKAGE

ENV NODE_PATH $NODE_HOME/lib/node_modules
ENV PATH $NODE_HOME/bin:$PATH

RUN curl https://nodejs.org/dist/v$NODE_VERSION/$NODE_PACKAGE.tar.gz | tar -xzC /opt/ \
  && npm install -g npm@9.2 \
  && npm install -g yarn

# COMPOSER
COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

# SYMFONY
RUN echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list

# PACKAGES
# add `libxrender-dev` for wkhtmltopdf
RUN apt-get update && apt-get install -y \
  libgd-dev \
  libicu-dev \
  libonig-dev \
  libsqlite3-dev \
  libzip-dev \
  make \
  ssl-cert \
  symfony-cli \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# HTTPD
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
  && a2enmod rewrite \
  && a2enmod headers \
  && a2enmod ssl

COPY docker/apache.conf /etc/apache2/sites-enabled/000-default.conf

# PHP
RUN docker-php-ext-configure zip && docker-php-ext-install \
  bcmath \
  exif \
  gd \
  intl \
  mbstring \
  mysqli \
  opcache \
  pdo_mysql \
  pdo_sqlite \
  zip

RUN pecl install apcu && docker-php-ext-enable apcu
COPY docker/apcu.ini "$PHP_INI_DIR/conf.d/"
COPY docker/tzone.ini "$PHP_INI_DIR/conf.d/"

RUN ln -s "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY docker/symfony.dev.ini "$PHP_INI_DIR/conf.d/"

# APPLICATION DATA
WORKDIR /var/www

FROM base as debug

ENV XDEBUG_MODE=off

RUN pecl install xdebug && docker-php-ext-enable xdebug
COPY docker/xdebug.ini "$PHP_INI_DIR/conf.d/"

# SERVICE
CMD [ "apache2-foreground" ]
ENTRYPOINT [ "/bin/bash", "docker/entrypoint.sh" ]
