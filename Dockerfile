FROM php:8.4-apache@sha256:4e4d213d34087fc762691319c0a6394c5a407d36fe6e2f107d033f8d441d6252

COPY --from=mlocati/php-extension-installer@sha256:63555d5a8f8b5bb026b0efb602aff9af23c56009feabd1dbab799429f41de413 /usr/bin/install-php-extensions /usr/local/bin/
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
COPY --from=composer:2.8@sha256:685473b4cd31d70bfe71926409f812d5dd9245972d38b659ba35d70f4007808c /usr/bin/composer /usr/bin/composer


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

COPY --from=wordpress@sha256:8b0ffd461bfaf8e74ab98481f45d1b2596986767faf2dc65bb47c875076f8a14 /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress@sha256:8b0ffd461bfaf8e74ab98481f45d1b2596986767faf2dc65bb47c875076f8a14 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress@sha256:8b0ffd461bfaf8e74ab98481f45d1b2596986767faf2dc65bb47c875076f8a14 /usr/src/wordpress /usr/src/wordpress

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
