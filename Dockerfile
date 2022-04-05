FROM php:8.1-apache

RUN apt-get update && apt-get install -y \ 
  curl \ 
  git \ 
  libgd-dev \ 
  libicu-dev \
  libonig-dev \
  libzip-dev \
  ssl-cert \
  && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite && a2enmod ssl 

RUN docker-php-ext-install \ 
  exif \
  gd \
  intl \ 
  mbstring \
  mysqli \
  opcache \
  pdo_mysql \
  zip

RUN pecl install apcu && docker-php-ext-enable apcu 

SHELL ["/bin/bash", "--login", "-c"]
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN nvm install node && npm install -g yarn

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY docker/apache.conf /etc/apache2/sites-enabled/000-default.conf 

WORKDIR /var/www
COPY . .

CMD ["apache2-foreground"]

ENTRYPOINT ["/bin/bash", "docker/entrypoint.sh"]
