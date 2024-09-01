FROM jfcoz/frankenphp-wordpress@sha256:0b3dabd9c37bd294a25db889e39d62db709106d39ee7a6a722ac4ef80efceac2
USER root

# Install the opentelemetry and protobuf extensions
RUN install-php-extensions \
    opentelemetry
#    protobuf \
#    grpc \

# Copy in the composer vendor files and autoload.php
#COPY --from=build /app/vendor /var/www/otel
COPY --from=composer:2.7@sha256:57000529b4609b66beeba3ebdd0ebb68b28be262c30669dfccb31003febb245a /usr/bin/composer /usr/bin/composer
RUN composer require \
    open-telemetry/sdk \
    open-telemetry/opentelemetry-auto-wordpress
#    open-telemetry/exporter-otlp \
#    grpc/grpc \
#    php-http/guzzle7-adapter

COPY otel.php.ini $PHP_INI_DIR/conf.d/.

# Use the default production configuration
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#COPY opcache.ini /usr/local/etc/php/conf.d/

USER www-data
