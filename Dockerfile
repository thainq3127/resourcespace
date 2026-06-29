FROM ubuntu:24.04

LABEL org.opencontainers.image.authors="Montala Ltd"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get install -y \
    nano \
    imagemagick \
    apache2 \
    subversion \
    ghostscript \
    antiword \
    poppler-utils \
    libimage-exiftool-perl \
    cron \
    postfix \
    wget \
    git \
    unzip \
    ca-certificates \
    composer \
    php \
    php-apcu \
    php-curl \
    php-dev \
    php-gd \
    php-intl \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-zip \
    libapache2-mod-php \
    ffmpeg \
    libopencv-dev \
    python3-opencv \
    python3 \
    python3-pip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/8.3/apache2/php.ini \
 && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/8.3/apache2/php.ini \
 && sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 300/g" /etc/php/8.3/apache2/php.ini \
 && sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1G/g" /etc/php/8.3/apache2/php.ini

RUN printf '<Directory /var/www/>\n\
\tOptions FollowSymLinks\n\
</Directory>\n'\
>> /etc/apache2/sites-enabled/000-default.conf \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf

ADD cronjob /etc/cron.daily/resourcespace

WORKDIR /var/www/html

RUN rm -f index.html

# This repository already contains the ResourceSpace source code.
# The upstream docker image checks out a release from SVN because its build
# context is a separate docker-only repository; here we copy the local fork.
COPY . /var/www/html/

# ResourceSpace requires Composer's vendor/autoload.php at runtime.
# Development dependencies are intentionally skipped for the runtime image.
RUN composer install --no-interaction --no-dev --optimize-autoloader --classmap-authoritative

RUN mkdir -p filestore \
 && chmod 777 filestore \
 && chmod -R 777 include/

# Copy custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start both cron and Apache
CMD ["/entrypoint.sh"]
