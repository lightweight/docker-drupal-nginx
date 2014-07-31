#This is a branch of 
#
# Note, I use this to access my containers -> nsenter: https://github.com/jpetazzo/nsenter

FROM    ubuntu:14.04
MAINTAINER Dave Lane <dave.lane@catalyst.net.nz> 
RUN echo "deb http://ucmirror.canterbury.ac.nz/ubuntu trusty main restricted universe multiverse" > /etc/apt/sources.list
RUN apt-get update
#RUN apt-get -y upgrade

# Keep upstart from complaining
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -nfs /bin/true /sbin/initctl

# Sort out Locale -> UTF-8, en_NZ
RUN apt-get -y install locales
RUN echo "en_NZ.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen en_NZ.UTF-8
ENV LANGUAGE en_NZ.UTF-8
ENV LANG en_NZ.UTF-8
ENV LC_ALL en_NZ.UTF-8

# hack due to this bug: https://github.com/dotcloud/docker/issues/6345 
RUN ln -sf /bin/true /usr/bin/chfn

# Basic Requirements - for a separate MariaDb container, see https://github.com/bnchdrff/dockerfiles/blob/master/mariadb
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server-5.5 mariadb-client-5.5 nginx php5-fpm php5-mysql php-apc pwgen python-setuptools curl git unzip drush 

# Further requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates 

# Drupal Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imap php5-memcache memcached mc
# install Composer and then Drush - https://github.com/drush-ops/drush
##RUN curl -sS https://getcomposer.org/installer | php
##RUN mv composer.phar /usr/local/bin/composer
##RUN composer global require drush/drush:6.*
###RUN sed -i '1i export PATH="/root/.composer/vendor/bin:$PATH"' /root/.bashrc
##RUN ln -sf /root/.composer/vendor/drush/drush/drush /usr/local/bin/drush
###RUN . /root/.bashrc
###RUN which drush 
#RUN drush help

# tidy up
RUN apt-get clean

# Make MariaDB listen on the outside
RUN sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
ADD ./nginx-site.conf /etc/nginx/sites-available/default

# Supervisor Config
RUN /usr/bin/easy_install supervisor
ADD ./supervisord.conf /etc/supervisord.conf

# Retrieve drupal
RUN mkdir /var/www; cd /var/www ; drush dl drupal 
RUN chmod a+w /var/www/drupal/sites/default
RUN mkdir /var/www/drupal/sites/default/files ; chown -R www-data:www-data /var/www/drupal

# Drupal Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# private expose
EXPOSE 80
EXPOSE 443

CMD ["/bin/bash", "/start.sh"]
