# From https://raw.githubusercontent.com/open-telemetry/opentelemetry-php-contrib/main/examples/instrumentation/Wordpress/autoinstrumented-wordpress.dockerfile

# Pull in dependencies with composer
FROM composer:2.7@sha256:e61fcaa4a0cd4c18a36f3e6cc06e150b02aed0d4a3a53bc1a02524e2aeaa7c0a as build
COPY composer.json ./
RUN composer install --ignore-platform-reqs

FROM jfcoz/frankenphp-wordpress@sha256:253a4b30967da4ba29f686ad416c159583367a6fa857b79633bc17f23cfd3c4c
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
