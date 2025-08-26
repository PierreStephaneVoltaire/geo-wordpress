<?php
/**
 * Custom WordPress configuration for S3, Redis, and database splitting
 */

// S3 Uploads Plugin Configuration
if (getenv('S3_UPLOADS_BUCKET')) {
    define('S3_UPLOADS_BUCKET', getenv('S3_UPLOADS_BUCKET'));
}
if (getenv('AWS_REGION')) {
    define('S3_UPLOADS_REGION', getenv('AWS_REGION'));
}
define('S3_UPLOADS_USE_INSTANCE_PROFILE', true);
define('S3_UPLOADS_AUTOENABLE', true);

// Redis Object Cache Configuration
if (getenv('WP_REDIS_HOST')) {
    define('WP_REDIS_HOST', getenv('WP_REDIS_HOST'));
}
if (getenv('WP_REDIS_PORT')) {
    define('WP_REDIS_PORT', (int) getenv('WP_REDIS_PORT'));
}
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_PREFIX', 'wp_' . (getenv('AWS_REGION') ?: 'default') . '_');

// Database Read/Write Splitting Configuration
if (getenv('DB_HOST_PRIMARY')) {
    define('DB_HOST_PRIMARY', getenv('DB_HOST_PRIMARY'));
}
if (getenv('DB_HOST_REPLICA')) {
    define('DB_HOST_REPLICA', getenv('DB_HOST_REPLICA'));
}

// Security enhancements
define('DISALLOW_FILE_EDIT', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('WP_AUTO_UPDATE_CORE', false);

// Performance optimizations
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
define('WP_CACHE', true);

// Session handling with Redis
ini_set('session.save_handler', 'redis');
if (getenv('WP_REDIS_HOST')) {
    ini_set('session.save_path', 'tcp://' . getenv('WP_REDIS_HOST') . ':' . (getenv('WP_REDIS_PORT') ?: '6379'));
}

// CloudFront integration
if (getenv('CLOUDFRONT_DOMAIN')) {
    define('WP_CONTENT_URL', 'https://' . getenv('CLOUDFRONT_DOMAIN') . '/wp-content');
}

// Debugging (disabled in production)
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);

// Multisite support (if needed in the future)
// define('WP_ALLOW_MULTISITE', true);
?>