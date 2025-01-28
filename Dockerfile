FROM php:8.2-cli AS base

WORKDIR /app

RUN apt update && \
    apt install -y unzip git libzip-dev && \
    docker-php-ext-install zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json ./

RUN composer install --no-dev

FROM base AS dev

RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

COPY ./docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY . .

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]

FROM base AS test

RUN composer require --dev phpunit/phpunit

COPY . .

# ./vendor/bin/phpunit --testdox tests
CMD ["./vendor/bin/phpunit", "--testdox", "tests"]

FROM base AS prod

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN rm -rf docker/ tests/

EXPOSE 80

CMD ["php", "-S", "0.0.0.0:80", "-t", "public"]