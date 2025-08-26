<?php
/**
 * HyperDB Configuration for WordPress Database Read/Write Splitting
 * This file configures database connections for Aurora Global Database
 */

// Database servers configuration
$wpdb->add_database(array(
    'host'     => getenv('DB_HOST_PRIMARY') ?: DB_HOST,
    'user'     => DB_USER,
    'password' => DB_PASSWORD,
    'name'     => DB_NAME,
    'write'    => 1,  // Primary server for writes
    'read'     => 1,  // Can also handle reads
    'dataset'  => 'global',
    'timeout'  => 0.2,
));

// Add replica server if available
if (getenv('DB_HOST_REPLICA') && getenv('DB_HOST_REPLICA') !== getenv('DB_HOST_PRIMARY')) {
    $wpdb->add_database(array(
        'host'     => getenv('DB_HOST_REPLICA'),
        'user'     => DB_USER,
        'password' => DB_PASSWORD,
        'name'     => DB_NAME,
        'write'    => 0,  // Read-only replica
        'read'     => 1,  // Handle read queries
        'dataset'  => 'global',
        'timeout'  => 0.2,
    ));
}

// Lag threshold for replica reads (in seconds)
$wpdb->lag_threshold = 3;

// Enable persistent connections
$wpdb->persistent = true;

// Connection timeout settings
$wpdb->check_tcp_responsiveness = true;
$wpdb->tcp_responsiveness_threshold = 0.5;

// Debug mode (disabled in production)
$wpdb->debug = false;

// Callback function for connection errors
$wpdb->add_callback('connection_error', function($database, $error) {
    error_log("Database connection error for {$database['host']}: " . $error);
});

// Load balancing configuration
$wpdb->read_servers_weight = array(
    // If replica exists, prefer it for reads to reduce primary load
    getenv('DB_HOST_REPLICA') ? 2 : 0,  // Replica weight
    1,  // Primary weight for reads
);
?>