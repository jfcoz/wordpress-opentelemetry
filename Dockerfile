FROM php:8.5-apache@sha256:96b50b7861cb6d1c10cd9f58c46b2c19606761a1209c20d410a509d4d1c935fd

COPY --from=mlocati/php-extension-installer@sha256:84950d61e2873817f814fd2c486d0143566a5b7aa36b9c926a138dafb9a07753 /usr/bin/install-php-extensions /usr/local/bin/
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
COPY --from=composer:2.9@sha256:f5e5bb7048c7b0182ea153fed4a63d021f3c77d4a654d6572da4a42aaff547e3 /usr/bin/composer /usr/bin/composer


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

COPY --from=wordpress@sha256:03e91f888c2beb1837d8aaca08ce2a7d043f20af7acc1dd680969a23ea671c4f /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=wordpress@sha256:03e91f888c2beb1837d8aaca08ce2a7d043f20af7acc1dd680969a23ea671c4f /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
COPY --from=wordpress@sha256:03e91f888c2beb1837d8aaca08ce2a7d043f20af7acc1dd680969a23ea671c4f /usr/src/wordpress /usr/src/wordpress

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
