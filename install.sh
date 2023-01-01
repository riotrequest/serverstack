# update package manager cache
apt-get update

# install nginx
apt-get install nginx -y

# install Apache
apt-get install apache2 -y

# install MariaDB
apt-get install mariadb-server mariadb-client -y

# install Memcached
apt-get install -y memcached

# enable and start the Memcached service
systemctl enable memcached
systemctl start memcached

# download the WP-CLI installer
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# make the WP-CLI installer executable
chmod +x wp-cli.phar

# move the WP-CLI installer to a directory in the system PATH
mv wp-cli.phar /usr/local/bin/wp

# secure MariaDB installation
mysql_secure_installation

# install PHP
apt-get install php7.4 libapache2-mod-php7.4 php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip -y

# enable Apache mod_rewrite module
a2enmod rewrite

# configure nginx as a reverse proxy to Apache
cat > /etc/nginx/sites-available/reverse-proxy.conf <<EOF
server {
    listen 80;
    server_name example.com www.example.com;
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# create symbolic link to enable the reverse proxy configuration
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/

# disable the default nginx configuration
rm /etc/nginx/sites-enabled/default

# restart nginx and Apache
systemctl restart nginx
systemctl restart apache2

# install fail2ban
apt-get install fail2ban -y

# configure fail2ban
cat > /etc/fail2ban/jail.d/nginx-http-auth.conf <<EOF
[nginx-http-auth]
enabled = true
port    = http,https
filter  = nginx-http-auth
logpath = /var/log/nginx/*error.log
maxretry = 3
bantime  = 3600
EOF

# restart fail2ban
systemctl restart fail2ban

# install ufw
apt-get install -y ufw

# enable ufw
ufw enable

# allow incoming connections on needed ports (SSH)
ufw allow 22 80 443 3306 9000 9999

# enable the ufw logging module
ufw logging on

# configure ufw to send email notifications when a rule is matched
cat > /etc/ufw/ufw.conf <<EOF
ENABLED=yes
LOGLEVEL=high
EMAIL=root
EOF

# install ModSecurity and related dependencies
apt-get install libapache2-mod-security2 -y

# configure ModSecurity
cat > /etc/modsecurity/modsecurity.conf <<EOF
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml
SecAuditEngine RelevantOnly
SecAuditLog /var/log/modsecurity/audit.log
SecAuditLogParts ABIFHZ
SecAuditLogRelevantStatus "^(?:5|4(?!04))"

# install the recommended ModSecurity rules
apt-get install libapache2-mod-security2-rules -y

# configure ModSecurity to block malicious HTTP requests
cat > /etc/modsecurity/modsecurity_crs_10_setup.conf <<EOF
Include modsecurity_crs_10_config.conf
Include modsecurity_crs_20_protocol_violations.conf
Include modsecurity_crs_30_http_policy.conf
Include modsecurity_crs_40_generic_attacks.conf
Include modsecurity_crs_50_outbound.conf
Include modsecurity_crs_60_correlation.conf
EOF

# enable ModSecurity for all virtual hosts
cat > /etc/apache2/conf-available/modsecurity.conf <<EOF
<IfModule security2_module>
    SecRuleEngine On
</IfModule>
EOF

a2enconf modsecurity

# restart Apache
systemctl restart apache2

# install Rootkit Hunter
apt-get install rkhunter -y

# run Rootkit Hunter and update its database
rkhunter --update
rkhunter --propupd

# create a cron job to run Rootkit Hunter daily
cat > /etc/cron.daily/rkhunter.sh <<EOF
#!/bin/bash
rkhunter --update
rkhunter --propupd --report-warnings-only
EOF

# make the cron job executable
chmod +x /etc/cron.daily/rkhunter.sh

# install ClamAV
apt-get install clamav clamav-daemon -y

# update ClamAV virus definitions
freshclam

# create a cron job to run ClamAV daily
cat > /etc/cron.daily/clamav.sh <<EOF
#!/bin/bash
freshclam
clamscan -r --bell -i /
EOF

# make the cron job executable
chmod +x /etc/cron.daily/clamav.sh

# install chkrootkit
apt-get install chkrootkit -y

# create a cron job to run chkrootkit daily
cat > /etc/cron.daily/chkrootkit.sh <<EOF
#!/bin/bash
chkrootkit
EOF

# make the cron job executable
chmod +x /etc/cron.daily/chkrootkit.sh

