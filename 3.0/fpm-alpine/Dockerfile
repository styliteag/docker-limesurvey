FROM php:7.3-fpm-alpine
LABEL maintainer="wb@stylite.de"
ARG version='3.22.14+200423'
ARG sha256_checksum='c148af72e9b26c7803c8e98815ffed1a7bd75b10eefc7791e3826c4dc9553b62'

# Install OS dependencies
RUN set -ex; \
        apk add --no-cache --virtual .build-deps \
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        openldap-dev \
        imap-dev \
        postgresql-dev \
        libltdl \
        tidyhtml-libs \
        libzip-dev \
        libsodium-dev && \
        apk add --no-cache netcat-openbsd bash rsync

# Install PHP Plugins
RUN set -ex; \
        docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr && \
        docker-php-ext-configure imap --with-imap-ssl && \
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
# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=2'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini

#Set PHP defaults for Limesurvey (allow bigger uploads)
RUN { \
                echo 'memory_limit=256M'; \
                echo 'upload_max_filesize=128M'; \
                echo 'post_max_size=128M'; \
                echo 'max_execution_time=120'; \
                echo 'max_input_vars=10000'; \
                echo 'date.timezone=UTC'; \
	} > /usr/local/etc/php/conf.d/uploads.ini

#VOLUME ["/var/www/html/plugins"]
#VOLUME ["/var/www/html/upload"]
VOLUME /var/www/html

RUN set -ex; \
        curl -SL https://github.com/LimeSurvey/LimeSurvey/archive/${version}.tar.gz -o /tmp/lime.tar.gz; \
        echo "${sha256_checksum}  /tmp/lime.tar.gz" | sha256sum -c - && \
        \
        mkdir -p /var/www/html-src && \
        tar xzvf "/tmp/lime.tar.gz" --strip-components=1 -C /var/www/html-src/ && \
        \
        rm -rf "/tmp/lime.tar.gz" \
        /var/www/html-src/docs \
        /var/www/html-src/tests \
        /var/www/html-src/*.md && \
        mkdir -p /var/www/html && \
        chown -R www-data:root /var/www/html /var/www/html-src && \
        chmod -R g=u           /var/www/html /var/www/html-src

EXPOSE 9000

COPY upgrade.exclude /upgrade.exclude

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]

EXPOSE 9000

COPY entrypoint.sh entrypoint.sh
ENTRYPOINT ["/var/www/html/entrypoint.sh"]
CMD ["php-fpm"]
