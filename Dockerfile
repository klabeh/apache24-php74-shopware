FROM debian:9

RUN apt-get clean

RUN apt-get update
RUN apt-get -y install wget curl apt-transport-https apache2 unzip redis-server git mysql-client

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list

RUN apt-get update

RUN apt-get -y install php7.4 php7.4-cli php7.4-redis php7.4-curl php7.4-gd php7.4-mbstring php7.4-imagick php7.4-mysql php7.4-simplexml php7.4-zip php7.4-soap php7.4-apcu php-apcu-bc php7.4-sqlite3 php7.4-intl php7.4-bcmath

# Install nodejs - needed for shopware 6 admin builds
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs

# Install composer - needed by psh.phar by SW6
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

#configure apache
RUN ["bin/bash", "-c", "sed -i 's/AllowOverride None/AllowOverride All\\nSetEnvIf X-Forwarded-Proto https HTTPS=on/g' /etc/apache2/apache2.conf"]
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN service apache2 stop

#set timezone
RUN apt-get -y install tzdata && ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

#configure php
RUN ["bin/bash", "-c", "sed -i 's/max_execution_time\\s*=.*/max_execution_time=180/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/upload_max_filesize\\s*=.*/upload_max_filesize=16M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/memory_limit\\s*=.*/memory_limit=512M/g' /etc/php/7*/apache2/php.ini"]
RUN ["bin/bash", "-c", "sed -i 's/post_max_size\\s*=.*/post_max_size=20M/g' /etc/php/7*/apache2/php.ini"]
RUN phpenmod redis

# Configure apache
RUN a2enmod rewrite
RUN a2enmod expires
#RUN a2enmod ssl
RUN a2enmod proxy
RUN a2enmod headers
# optionally enable ssl on apache - however, ssl termination is intended to be done by jwilder/nginx-proxy instead
# RUN a2ensite default-ssl
RUN chown -R www-data:www-data /var/www
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN a2dissite 000-default.conf
COPY ./conf/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default.conf

# Add PageSpeed
RUN wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
RUN dpkg -i mod-pagespeed-stable_current_amd64.deb
RUN apt-get -f install
RUN echo "ModPagespeed Off" > /etc/apache2/mods-available/pagespeed.conf
#RUN echo "ModPagespeedInheritVHostConfig on" >> /etc/apache2/mods-available/pagespeed.conf
#RUN echo "ModPagespeedFileCachePath \"/var/cache/mod_pagespeed/\"" >> /etc/apache2/mods-available/pagespeed.conf
#RUN echo "ModPagespeedEnableFilters combine_css,combine_javascript" >> /etc/apache2/mods-available/pagespeed.conf
#RUN echo "# Direct Apache to send all HTML output to the mod_pagespeed" >> /etc/apache2/mods-available/pagespeed.conf
#RUN echo "# output handler." > /etc/apache2/mods-available/pagespeed.conf
#RUN echo "AddOutputFilterByType MOD_PAGESPEED_OUTPUT_FILTER text/html" > /etc/apache2/mods-available/pagespeed.conf

EXPOSE 80
#EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
