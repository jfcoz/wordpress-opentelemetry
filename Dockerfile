# From https://raw.githubusercontent.com/open-telemetry/opentelemetry-php-contrib/main/examples/instrumentation/Wordpress/autoinstrumented-wordpress.dockerfile

# Pull in dependencies with composer
FROM composer:2.7@sha256:4c01e0b94ce1cf09a1f0850187231f48942dab2ab25f5bb0a34dfd6271c289b1 as build
COPY composer.json ./
RUN composer install --ignore-platform-reqs

FROM jfcoz/frankenphp-wordpress@sha256:d2b81db89e02411965130086d0a5ba3461141f2da8d9cc8bf8fd6ae6147b988b
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
