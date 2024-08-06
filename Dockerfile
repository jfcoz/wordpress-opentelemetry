# From https://raw.githubusercontent.com/open-telemetry/opentelemetry-php-contrib/main/examples/instrumentation/Wordpress/autoinstrumented-wordpress.dockerfile

# Pull in dependencies with composer
FROM composer:2.7@sha256:2088445f2bcaea6fe72cefcdd9ef0cb75139ee103459cc0d1dad496e19847d2c as build
COPY composer.json ./
RUN composer install --ignore-platform-reqs

FROM jfcoz/frankenphp-wordpress@sha256:6a79d3d1e7ea74413ab9418a99fa50ddff3b82dd218f1e1acd00bbf40a83c365
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
