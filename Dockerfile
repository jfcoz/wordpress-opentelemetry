FROM php:8.4-apache@sha256:432ae092a1aafd4b8c7817070edfc47b620a6ceac8ac1829cf6d2c699e3c988f

COPY --from=mlocati/php-extension-installer@sha256:a7d3e11e022dbc563c85d3c71827cc3a0a338640bcb4dc629ce3e98bcd5875e4 /usr/bin/install-php-extensions /usr/local/bin/
# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)

RUN install-php-extensions bcmath
RUN install-php-extensions exif
RUN install-php-extensions gd
RUN install-php-extensions intl
RUN install-php-extensions mysqli
RUN install-php-extensions zip
RUN install-php-extensions imagick
RUN install-php-extensions opcache

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
COPY --from=composer:2.8@sha256:9f2a31e610b009bbf38cbc378384f74b60295dbe44ac0dd6077b5f74391dd15e /usr/bin/composer /usr/bin/composer


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

COPY --from=wordpress@sha256:eb11637b7450a04b1320e627ababc1804d1cb2ed3ee3d452a1cf6dfda01e3829 /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress@sha256:eb11637b7450a04b1320e627ababc1804d1cb2ed3ee3d452a1cf6dfda01e3829 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress@sha256:eb11637b7450a04b1320e627ababc1804d1cb2ed3ee3d452a1cf6dfda01e3829 /usr/src/wordpress /usr/src/wordpress

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
