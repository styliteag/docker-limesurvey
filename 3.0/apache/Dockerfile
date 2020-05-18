FROM php:7.3-apache
LABEL maintainer="wb@stylite.de"
ARG version='3.22.14+200423'
ARG sha256_checksum='c148af72e9b26c7803c8e98815ffed1a7bd75b10eefc7791e3826c4dc9553b62'

# Install OS dependencies
RUN set -ex; \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive \
        apt-get install --no-install-recommends -y \
        libldap2-dev \
        libfreetype6-dev \
        libjpeg-dev \
        zlib1g-dev \
        libc-client-dev \
        libkrb5-dev \
        libpng-dev \
        libpq-dev \
        netcat \
        libzip-dev \
        libsodium-dev \
        \
        && apt-get -y autoclean && apt-get -y autoremove && \
        rm -rf /var/lib/apt/lists/*

# Link LDAP library for PHP ldap extension
RUN set -ex; \
        ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/

# Install PHP Plugins and Configure PHP imap plugin
RUN set -ex; \
        docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr; \
        docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
        docker-php-ext-install \
        mysqli \
        opcache \
        iconv \
        ldap \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        exif \
        sodium \
        zip 

ENV LIMESURVEY_VERSION=$version

# Apache configuration
RUN a2enmod headers rewrite remoteip; \
        {\
        echo RemoteIPHeader X-Real-IP ;\
        echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
        echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
        echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
        } > /etc/apache2/conf-available/remoteip.conf;\
        a2enconf remoteip

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=2'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > $PHP_INI_DIR/conf.d/opcache-recommended.ini

#Set PHP defaults for Limesurvey (allow bigger uploads)
RUN { \
                echo 'memory_limit=256M'; \
                echo 'upload_max_filesize=128M'; \
                echo 'post_max_size=128M'; \
                echo 'max_execution_time=120'; \
                echo 'max_input_vars=10000'; \
                echo 'date.timezone=UTC'; \
	} > $PHP_INI_DIR/conf.d/uploads.ini


RUN set -ex; \
        curl -SL https://github.com/LimeSurvey/LimeSurvey/archive/${version}.tar.gz -o /tmp/lime.tar.gz; \
        echo "${sha256_checksum}  /tmp/lime.tar.gz" | sha256sum -c - && \
        \
        tar xzvf "/tmp/lime.tar.gz" --strip-components=1 -C /var/www/html/ && \
        rm -f "/tmp/lime.tar.gz" && \
        chown -R www-data:www-data /var/www/html

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
