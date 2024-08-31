# From https://raw.githubusercontent.com/open-telemetry/opentelemetry-php-contrib/main/examples/instrumentation/Wordpress/autoinstrumented-wordpress.dockerfile

# Pull in dependencies with composer
FROM composer:2.7@sha256:57000529b4609b66beeba3ebdd0ebb68b28be262c30669dfccb31003febb245a as build
COPY composer.json ./
RUN composer install --ignore-platform-reqs

FROM jfcoz/frankenphp-wordpress@sha256:2a323e90ddf3dc32fb7acd7a928d529ed268df98b850895dd382bfd3a9520bfd
USER root

# Install the opentelemetry and protobuf extensions
RUN install-php-extensions \
    protobuf \
    grpc \
    opentelemetry
COPY otel.php.ini $PHP_INI_DIR/conf.d/.
# Copy in the composer vendor files and autoload.php
COPY --from=build /app/vendor /var/www/otel

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY opcache.ini /usr/local/etc/php/conf.d/

USER www-data
