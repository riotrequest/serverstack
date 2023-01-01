#!/bin/bash

# get the domain name from the first argument
domain=$1

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
