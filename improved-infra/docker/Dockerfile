# Custom WordPress image with required plugins for S3, Redis, and database splitting
FROM wordpress:6.4-apache

# Install additional PHP extensions
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Create plugins directory
RUN mkdir -p /usr/src/wordpress/wp-content/plugins

# Install S3 Uploads Plugin
WORKDIR /usr/src/wordpress/wp-content/plugins
RUN wget https://github.com/humanmade/S3-Uploads/archive/refs/heads/master.zip -O s3-uploads.zip \
    && unzip s3-uploads.zip \
    && mv S3-Uploads-master s3-uploads \
    && rm s3-uploads.zip

# Install Redis Object Cache Plugin
RUN wget https://downloads.wordpress.org/plugin/redis-cache.3.1.4.zip -O redis-cache.zip \
    && unzip redis-cache.zip \
    && rm redis-cache.zip

# Install HyperDB for database read/write splitting
RUN wget https://downloads.wordpress.org/plugin/hyperdb.1.8.zip -O hyperdb.zip \
    && unzip hyperdb.zip \
    && rm hyperdb.zip

# Copy custom WordPress configuration
COPY wp-config-extra.php /usr/src/wordpress/
COPY db-config.php /usr/src/wordpress/
COPY entrypoint.sh /usr/local/bin/

# Make entrypoint executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]