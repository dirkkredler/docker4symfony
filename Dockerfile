FROM php:8.1-apache

# USER to change the application data in the container
ARG UNAME
ARG UID
ARG GID

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -G www-data -o -s /bin/bash $UNAME

ENV UID=$UID
ENV GID=$GID

# NODE
ARG NODE_VERSION
ARG NODE_ARCH
ARG NODE_PACKAGE=node-v$NODE_VERSION-$NODE_ARCH
ARG NODE_HOME=/opt/$NODE_PACKAGE

ENV NODE_PATH $NODE_HOME/lib/node_modules
ENV PATH $NODE_HOME/bin:$PATH

RUN curl https://nodejs.org/dist/v$NODE_VERSION/$NODE_PACKAGE.tar.gz | tar -xzC /opt/ \
  && npm install -g yarn

# COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# SYMFONY
RUN echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list

# PACKAGES
RUN apt-get update && apt-get install -y \
  curl \
  git \
  libgd-dev \
  libicu-dev \
  libonig-dev \
  libzip-dev \
  make \
  ssl-cert \
  symfony-cli \
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
  zip

RUN pecl install apcu && docker-php-ext-enable apcu \
  && printf "%s\n" "apc.enabled=1" "apc.enable_cli=1" >> "$PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini" \
  && printf "%s\n" "[PHP]" "date.timezone = 'Europe/Berlin'" > "$PHP_INI_DIR/conf.d/tzone.ini" \
  && ln -s "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

COPY docker/symfony.dev.ini "$PHP_INI_DIR/conf.d/"

# APPLICATION DATA
WORKDIR /var/www

# SERVICE
CMD [ "apache2-foreground" ]
ENTRYPOINT [ "/bin/bash", "docker/entrypoint.sh" ]
