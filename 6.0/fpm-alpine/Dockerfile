FROM docker.io/php:8.3-fpm-alpine
LABEL maintainer="markus@martialblog.de"

# Install OS dependencies
RUN set -ex; \
        apk add --no-cache \
        netcat-openbsd \
        libsasl \
        libldap \
        bash

# Install PHP Plugins
# hadolint ignore=SC2086
RUN set -ex; \
        apk add --no-cache --virtual .build-deps \
        freetype-dev \
        libpng-dev \
        libzip-dev \
        libjpeg-turbo-dev \
        tidyhtml-dev \
        libsodium-dev \
        openldap-dev \
        oniguruma-dev \
        imap-dev \
        postgresql-dev \
    ; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-configure imap --with-imap-ssl; \
    docker-php-ext-install -j "$(nproc)" \
        exif \
        gd \
        imap \
        ldap \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        sodium \
        tidy \
        zip \
    ; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --no-network --virtual .limesurvey-phpext-rundeps $runDeps; \
    apk del --no-cache --no-network .build-deps

ARG version="6.15.4+250710"
ARG sha256_checksum="540150c09a4658d00cc759b4051558fa07d3206049b5344701f137c49e569b49"
ARG archive_url="https://github.com/LimeSurvey/LimeSurvey/archive/refs/tags/${version}.tar.gz"
ARG USER=www-data
ENV LIMESURVEY_VERSION=$version

# Download, unzip and chmod LimeSurvey from GitHub (defaults to the official LimeSurvey/LimeSurvey repository)
RUN set -ex; \
        curl -sSL "${archive_url}" --output /tmp/limesurvey.tar.gz && \
        echo "${sha256_checksum}  /tmp/limesurvey.tar.gz" | sha256sum -c - && \
        \
        tar xzvf "/tmp/limesurvey.tar.gz" --strip-components=1 -C /var/www/html/ && \
        \
        rm -rf "/tmp/limesurvey.tar.gz" \
        /var/www/html/docs \
        /var/www/html/tests \
        /var/www/html/*.md && \
        chown -R "${USER}:root" /var/www/ ; \
        chmod -R g=u /var/www

EXPOSE 9000

WORKDIR /var/www/html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
USER $USER
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
