#!/bin/bash
set -euo pipefail

# WordPress custom entrypoint script
echo "Starting WordPress with AWS integrations..."

# Get secrets from AWS Parameter Store if running in AWS
if [ "${AWS_REGION:-}" ]; then
    echo "Fetching configuration from AWS Parameter Store..."
    
    # Set AWS region
    export AWS_DEFAULT_REGION="${AWS_REGION}"
    
    # Fetch database configuration
    if [ "${PARAMETER_STORE_PREFIX:-}" ]; then
        echo "Using Parameter Store prefix: ${PARAMETER_STORE_PREFIX}"
        
        # Try to get parameters (will use IAM role attached to ECS task)
        export S3_UPLOADS_BUCKET="${S3_UPLOADS_BUCKET:-$(aws ssm get-parameter --name "${PARAMETER_STORE_PREFIX}/s3/bucket_name" --query 'Parameter.Value' --output text 2>/dev/null || echo '')}"
    fi
fi

# Ensure WordPress directory exists
mkdir -p /var/www/html

# Copy WordPress files if not already present
if [ ! -f /var/www/html/index.php ]; then
    echo "Installing WordPress..."
    cp -a /usr/src/wordpress/. /var/www/html/
fi

# Copy and activate plugins
echo "Installing and configuring plugins..."

# S3 Uploads Plugin
if [ ! -d /var/www/html/wp-content/plugins/s3-uploads ]; then
    cp -r /usr/src/wordpress/wp-content/plugins/s3-uploads /var/www/html/wp-content/plugins/
fi

# Redis Object Cache Plugin
if [ ! -d /var/www/html/wp-content/plugins/redis-cache ]; then
    cp -r /usr/src/wordpress/wp-content/plugins/redis-cache /var/www/html/wp-content/plugins/
fi

# HyperDB Plugin
if [ ! -d /var/www/html/wp-content/plugins/hyperdb ]; then
    cp -r /usr/src/wordpress/wp-content/plugins/hyperdb /var/www/html/wp-content/plugins/
fi

# Copy HyperDB drop-in
if [ -f /usr/src/wordpress/wp-content/plugins/hyperdb/db.php ]; then
    cp /usr/src/wordpress/wp-content/plugins/hyperdb/db.php /var/www/html/wp-content/
fi

# Append custom configuration to wp-config.php if it exists
if [ -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/.custom-config-added ]; then
    echo "Adding custom WordPress configuration..."
    
    # Create backup
    cp /var/www/html/wp-config.php /var/www/html/wp-config.php.backup
    
    # Insert custom config before the "That's all" line
    sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i\\
/* Custom AWS Configuration */\\
require_once(ABSPATH . 'wp-config-extra.php');\\
if (file_exists(ABSPATH . 'db-config.php')) {\\
    require_once(ABSPATH . 'db-config.php');\\
}\\
" /var/www/html/wp-config.php
    
    # Copy custom config files
    cp /usr/src/wordpress/wp-config-extra.php /var/www/html/
    cp /usr/src/wordpress/db-config.php /var/www/html/
    
    # Mark as configured
    touch /var/www/html/.custom-config-added
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# WordPress CLI setup (optional)
if [ ! -f /usr/local/bin/wp ]; then
    echo "Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

echo "WordPress setup complete. Starting Apache..."

# Execute the original WordPress entrypoint
exec docker-entrypoint.sh "$@"