#!/bin/bash

# disable wp-cron.php in WordPress
echo "Disabling wp-cron.php in WordPress..."
echo "define('DISABLE_WP_CRON', true);" >> wp-config.php

# add a system cron job to run wp-cron.php every 5 minutes
echo "Adding a system cron job to run wp-cron.php every 5 minutes..."
echo "*/5 * * * * wget -q -O - http://your-website.com/wp-cron.php >/dev/null 2>&1" | crontab -

echo "Done!"
