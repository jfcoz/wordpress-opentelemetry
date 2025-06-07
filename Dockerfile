FROM php:8.4-apache@sha256:6b0e0ad94d91b919902dc541fe6a89d37fcb55debb2e7d1b90554480fc301c44

COPY --from=mlocati/php-extension-installer@sha256:f6315f2a45e59a10f0bd6f98f8080a21be953acd7200f156d168c1747f93ad9e /usr/bin/install-php-extensions /usr/local/bin/
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
COPY --from=composer:2.8@sha256:016f264ffffc1c3e957c7bd91bfcecfe2a70952678fbec73fd78779e323f072c /usr/bin/composer /usr/bin/composer


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

COPY --from=wordpress@sha256:56c5be977240677109850ccc49412f8e492d0c56a0d01cc1d114c2ed10a69049 /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress@sha256:56c5be977240677109850ccc49412f8e492d0c56a0d01cc1d114c2ed10a69049 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress@sha256:56c5be977240677109850ccc49412f8e492d0c56a0d01cc1d114c2ed10a69049 /usr/src/wordpress /usr/src/wordpress

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
