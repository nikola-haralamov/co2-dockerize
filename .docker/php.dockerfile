FROM php:8-fpm-alpine

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

RUN apk update && apk upgrade && \
    apk --no-cache add bash build-base gcc wget curl sed git openssh-client  \
    autoconf libmcrypt-dev libzip-dev zip g++ make libffi-dev openssl-dev \
    sqlite curl-dev libxml2-dev

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# MacOS staff group's gid is 20, so is the dialout group in alpine linux. We're not using it, let's just remove it.
RUN delgroup dialout

RUN addgroup -g ${GID} --system laravel
RUN adduser -G laravel --system -D -s /bin/sh -u ${UID} laravel

RUN sed -i "s/user = www-data/user = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = laravel/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

RUN docker-php-ext-install bcmath bz2 calendar ctype curl dba dl_test dom \
    exif ffi fileinfo filter ftp gd gettext gmp hash iconv intl json ldap mbstring  \
    mysqli odbc opcache pcntl pdo pdo_mysql \
    phar posix random readline reflection session shmop simplexml snmp soap sockets sodium \
    spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlwriter xsl zip


#RUN docker-php-ext-install pdo
#RUN docker-php-ext-install pdo_sqlite
#RUN docker-php-ext-install mysqli pdo_mysql
#RUN docker-php-ext-install pgsql pdo_pgsql
#RUN docker-php-ext-install bcmath bz2 gd curl dom exif fileinfo filter ftp gettext gmp hash
#RUN docker-php-ext-install iconv imap intl json mbstring mcrypt phar session
#RUN docker-php-ext-install soap sockets tokenizer xml simplexml xmlwriter
#RUN docker-php-ext-install zip yaml xsl ctype openssl

RUN pecl install redis && docker-php-ext-enable redis

#RUN mkdir -p /usr/src/php/ext/redis \
#    && curl -L https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
#    && echo 'redis' >> /usr/src/php-available-exts \
#    && docker-php-ext-install redis

USER laravel

CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
