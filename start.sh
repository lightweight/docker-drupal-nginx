#!/bin/bash
if [ ! -f /var/www/drupal/sites/default/settings.php ]; then
  # Start mysql
  /usr/bin/mysqld_safe & 
  sleep 10s
  # Generate random passwords   
  DRUPAL_DB="drupal"
  MYSQL_PASSWORD=`pwgen -c -n -1 12`
  DRUPALDB_PASSWORD=`pwgen -c -n -1 12`
  ADMIN_PASSWORD=`pwgen -c -n -1 12`
  # This is so the passwords show up in logs. 
  echo mysql root password: $MYSQL_PASSWORD
  echo drupaldb password: $DRUPALDB_PASSWORD
  echo drupal admin password: $ADMIN_PASSWORD
  echo $MYSQL_PASSWORD > /mysql-root-pw.txt
  echo $DRUPALDB_PASSWORD > /drupal-db-pw.txt
  echo $ADMIN_PASSWORD > /drupal-admin-pw.txt
  mysqladmin -u root password $MYSQL_PASSWORD 
  mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE drupal; GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost' IDENTIFIED BY '$DRUPALDB_PASSWORD'; FLUSH PRIVILEGES;"
  cd /var/www/drupal
  # set up default site here
  drush site-install standard -y --account-name=admin --account-pass=admin --db-url="mysqli://drupal:${DRUPALDB_PASSWORD}@localhost:3306/drupal"
  # grab site from Git and install a preconfigured database - what about Drush Make...
  
  # prepare to allow supervisord to take over management of MySQL/MariaDB
  killall mysqld
  sleep 10s
fi

# start all the services
/usr/local/bin/supervisord -n
