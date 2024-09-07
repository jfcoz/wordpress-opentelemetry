FROM jfcoz/frankenphp-wordpress@sha256:a5be32fcfb95f30848fa71cb774dc49b812e8bd35a312028137e916c20e19511
USER root

# Install the opentelemetry and protobuf extensions
# grpc: longuest build first, and strip debug symbols: https://github.com/grpc/grpc/issues/34278
#RUN install-php-extensions grpc \
# && strip --strip-debug /usr/local/lib/php/extensions/*/grpc.so
RUN install-php-extensions opentelemetry
#RUN install-php-extensions protobuf

# Copy in the composer vendor files and autoload.php
#COPY --from=build /app/vendor /var/www/otel
COPY --from=composer:2.7@sha256:8008ba4d8723edf5f3566bd94e9330a5cdff3d6125ed34a8502718f8d2289515 /usr/bin/composer /usr/bin/composer
RUN composer require \
    open-telemetry/sdk \
    open-telemetry/opentelemetry-auto-wordpress
# \
#    open-telemetry/exporter-otlp \
#    grpc/grpc \
#    php-http/guzzle7-adapter

#COPY otel.php.ini $PHP_INI_DIR/conf.d/.

# Use the default production configuration
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#COPY opcache.ini /usr/local/etc/php/conf.d/

USER www-data
