FROM debian:jessie

MAINTAINER ideaScale Test.
#WORKDIR /simplesaml
RUN apt-get -y update \
    &&  apt-get -y install  nginx  wget curl net-tools \
    && chown -R www-data:www-data /var/lib/nginx

RUN apt-get -y install apt-transport-https ca-certificates software-properties-common
RUN curl -fsSL https://packages.sury.org/php/apt.gpg | apt-key add -
RUN add-apt-repository "deb https://packages.sury.org/php/ $(lsb_release -cs) main"
RUN apt-get update
# fcgiwrap
RUN apt-get -y install php php-cli php-common php-mbstring php-fpm php-gd php-readline
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
#RUN php composer.phar install
RUN ssp_version=1.15.4; \
    ssp_hash=349cf5d9f9ecbbced0e6f6794d26d5242fc9dafbd34268aeeb200182c24f88a5; \
    wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
	&& cd /var \
	&& tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp \
    && rm /simplesamlphp-$ssp_version.tar.gz

# Define mountable directories.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

# REMOVE NGINX DEFAULT CONFIG FILE
COPY config/server.conf /
RUN  cat /server.conf > /etc/nginx/sites-available/default \
    && rm -rf /server.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


# MODIFY NGINX TO PREVENT DISPLAY NGINX VERSION
RUN sed -i 's/# server_tokens off/server_tokens off/g' /etc/nginx/nginx.conf  \
    && sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini


# CONFIG STANDARD ERROR LOG
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
RUN echo "<?php phpinfo(); ?>" > /var/simplesamlphp/www/info.php

# EXPOSING PORTS & ENDPOINT
EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

