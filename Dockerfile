FROM    ubuntu:latest
MAINTAINER Ricardo Amaro <mail@ricardoamaro.com>
RUN echo "deb http://ucmirror.canterbury.ac.nz/ubuntu trusty main restricted universe multiverse" > /etc/apt/sources.list
RUN apt-get update
#RUN apt-get -y upgrade

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -nfs /bin/true /sbin/initctl

# hack due to this bug: https://github.com/dotcloud/docker/issues/6345 
RUN ln -sf /bin/true /usr/bin/chfn

# Basic Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server-5.5 mariadb-client-5.5 nginx php5-fpm php5-mysql php-apc pwgen python-setuptools curl git unzip

# Drupal Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-curl php5-gd php5-intl php-pear php5-imap php5-memcache memcached drush mc

RUN apt-get clean

# Make mysql listen on the outside
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
RUN rm -rf /var/www/ ; cd /var ; drush dl drupal ; mv /var/drupal*/ /var/www/
RUN chmod a+w /var/www/sites/default ; mkdir /var/www/sites/default/files ; chown -R www-data:www-data /var/www/

# Drupal Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

# private expose
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
