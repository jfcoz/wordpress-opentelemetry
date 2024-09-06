FROM jfcoz/frankenphp-wordpress@sha256:c9b4af1cc628be95a6449097373040146b2a33517100ebf9ee5aba7d60e64eb2
USER root

# Install the opentelemetry and protobuf extensions
# grpc: longuest build first, and strip debug symbols: https://github.com/grpc/grpc/issues/34278
#RUN install-php-extensions grpc \
# && strip --strip-debug /usr/local/lib/php/extensions/*/grpc.so
RUN install-php-extensions opentelemetry
#RUN install-php-extensions protobuf

# Copy in the composer vendor files and autoload.php
#COPY --from=build /app/vendor /var/www/otel
COPY --from=composer:2.7@sha256:0600ced6504abc48f4e691bab15c00fd0afd6b388593f7237ba2bf4b8b3f1615 /usr/bin/composer /usr/bin/composer
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
