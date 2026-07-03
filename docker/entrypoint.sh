#!/bin/bash
set -e

# Fix permissions for WHMCS writable directories
WRITABLE_DIRS=(
    /var/www/html/templates_c
    /var/www/html/downloads
    /var/www/html/attachments
)

for dir in "${WRITABLE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        chown -R www-data:www-data "$dir"
        chmod -R 755 "$dir"
    fi
done

# Ensure configuration.php is writable during install
if [ -f /var/www/html/configuration.php ]; then
    chown www-data:www-data /var/www/html/configuration.php
    chmod 644 /var/www/html/configuration.php
fi

# Setup WHMCS cron job (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/php -q /var/www/html/crons/cron.php >> /var/log/whmcs-cron.log 2>&1" | crontab -
service cron start

echo "[entrypoint] Cron job started (every 5 minutes)"

# Run the original command (apache2-foreground)
exec "$@"
