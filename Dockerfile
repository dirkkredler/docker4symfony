FROM php:8.1-apache

SHELL ["/bin/bash", "--login", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN nvm install node && npm install -g yarn

RUN echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list
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

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite && a2enmod ssl 

RUN docker-php-ext-configure zip && docker-php-ext-install \ 
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

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY docker/apache.conf /etc/apache2/sites-enabled/000-default.conf 

WORKDIR /var/www
COPY . .

CMD ["apache2-foreground"]

ENTRYPOINT ["/bin/bash", "docker/entrypoint.sh"]
