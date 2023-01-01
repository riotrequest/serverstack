#!/bin/bash

# get the domain name from the first argument
domain=$1

# generate a random password for the MySQL user
password=$(pwgen -s 12 1)

# create a new directory for the website
mkdir -p /var/www/$domain/public_html

# create a new Apache virtual host configuration file
cat > /etc/apache2/sites-available/$domain.conf <<EOF
<VirtualHost *:8080>
    ServerAdmin webmaster@$domain
    DocumentRoot /var/www/$domain/public_html
    ServerName $domain
    ServerAlias www.$domain
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# enable the new virtual host
ln -s /etc/apache2/sites-available/$domain.conf /etc/apache2/sites-enabled/

# restart Apache to apply the changes
systemctl restart apache2

# add a new server block to the nginx configuration file
cat >> /etc/nginx/sites-available/reverse-proxy.conf <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# restart nginx to apply the changes
systemctl restart nginx

# create a new MySQL database and user for the website
mysql -u root -p <<EOF
CREATE DATABASE $domain;
GRANT ALL PRIVILEGES ON $domain.* TO '$domain'@'localhost' IDENTIFIED BY '$password';
FLUSH PRIVILEGES;
EOF

# download and extract WordPress
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm latest.tar.gz
mv wordpress/* /var/www/$domain/public_html

# copy the sample configuration file and modify it with the new database information
cp /var/www/$domain/public_html/wp-config-sample.php /var/www/$domain/public_html/wp-config.php
sed -i "s/database_name_here/$domain/g" /var/www/$domain/public_html/wp-config.php
sed -i "s/username_here/$domain/g" /var/www/$domain/public_html/wp-config.php
sed -i "s/password_here/$password/g" /var/www/$domain/public_html/wp-config.php

# change the ownership of the website directory to the Apache user
chown -R www-data:www-data /var/www/$domain/public_html

# create a new .htaccess file to block access to the WordPress config file
cat > /var/www/$domain/public_html/.htaccess <<EOF
<Files wp-config.php>
order allow,deny
deny from all
</Files>
EOF

# print the MySQL password to the console
echo "MySQL password: $password"
