FROM php:8.5-apache@sha256:a7f6cd2eb0abb309df61601599a9d57a63073f5ab57faeea90584480ae0b6f89

COPY --from=mlocati/php-extension-installer@sha256:2600c40be51e5cad9e0759bf307c88e316669b88bbec594148e0d91fceb1c013 /usr/bin/install-php-extensions /usr/local/bin/
# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)

RUN install-php-extensions bcmath
RUN install-php-extensions exif
RUN install-php-extensions gd
RUN install-php-extensions intl
RUN install-php-extensions mysqli
RUN install-php-extensions zip
RUN install-php-extensions imagick

#FROM jfcoz/frankenphp-wordpress@sha256:0b3dabd9c37bd294a25db889e39d62db709106d39ee7a6a722ac4ef80efceac2
#USER root

# Install the opentelemetry and protobuf extensions
# grpc: longuest build first, and strip debug symbols: https://github.com/grpc/grpc/issues/34278
#RUN install-php-extensions grpc \
# && strip --strip-debug /usr/local/lib/php/extensions/*/grpc.so
RUN install-php-extensions opentelemetry
RUN install-php-extensions protobuf

RUN a2enmod rewrite

# Copy in the composer vendor files and autoload.php
#COPY --from=build /app/vendor /var/www/otel
COPY --from=composer:2.9@sha256:8b4d59fde3bd505c5fef70c9f8d5c05e92af811fed037dad12869b373925ed31 /usr/bin/composer /usr/bin/composer


RUN mkdir /vendor \
    && cd /vendor \
    && composer require \
      open-telemetry/sdk \
      open-telemetry/opentelemetry-auto-wordpress \
      open-telemetry/exporter-otlp \
      php-http/guzzle7-adapter
#    grpc/grpc \

COPY otel.php.ini $PHP_INI_DIR/conf.d/.

# Use the default production configuration
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#COPY opcache.ini /usr/local/etc/php/conf.d/

USER www-data

COPY --from=wordpress@sha256:df465eeb57159be7e45b8c84459dbda72a978ee25990c96924b07afffce1ecbf /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress@sha256:df465eeb57159be7e45b8c84459dbda72a978ee25990c96924b07afffce1ecbf /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress@sha256:df465eeb57159be7e45b8c84459dbda72a978ee25990c96924b07afffce1ecbf /usr/src/wordpress /usr/src/wordpress

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
