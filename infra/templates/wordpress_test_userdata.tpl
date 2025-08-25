#cloud-config
# WordPress test instance with Ansible automation
# Template variables: region, db_region, project_name, environment, db_endpoint_param, db_username_param, db_password_param, s3_bucket_param, primary_db_endpoint_param, admin_email
package_update: true
package_upgrade: true

packages:
  - python3
  - python3-pip
  - git
  - unzip
  - wget
  - ansible
  - php-devel
  - gcc
  - make
  - php-pear

runcmd:
  # Enable SSM agent
  - systemctl enable amazon-ssm-agent
  - systemctl start amazon-ssm-agent
  - pip3 install boto3 botocore
  - useradd -m -s /bin/bash ansible
  - usermod -aG wheel ansible
  - echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
  - mkdir -p /tmp/ansible/{roles,playbooks}
  - |
    # Install APCu with PECL
    pecl install apcu
    echo "extension=apcu.so" > /etc/php.d/apcu.ini
  - ansible-galaxy collection install community.mysql amazon.aws --force
  - ansible-galaxy install geerlingguy.apache geerlingguy.php geerlingguy.mysql --force --roles-path /tmp/ansible/roles
  - |
    cat <<'EOF' > /tmp/ansible/playbooks/wordpress.yml
    ---
    - hosts: localhost
      connection: local
      become: yes
      gather_facts: yes
      vars:
        # Get database credentials from Parameter Store - use Singapore primary for initial setup
        db_host: "{{ lookup('aws_ssm', '${primary_db_endpoint_param}', region='ap-southeast-1') | regex_replace(':3306$', '') }}"
        db_name: "wordpress"
        db_user: "{{ lookup('aws_ssm', '${db_username_param}', region='${region}') }}"
        db_password: "{{ lookup('aws_ssm', '${db_password_param}', region='${region}') }}"
        s3_bucket: "{{ lookup('aws_ssm', '${s3_bucket_param}', region='${region}', errors='ignore') | default('') }}"
        distribution_domain_name: "{{ lookup('aws_ssm', '${distribution_domain_name}', region='${region}', errors='ignore') | default('') }}"

        # Apache and PHP configuration
        apache_enablerepo: ""
        apache_listen_ip: "*"
        apache_listen_port: 80
        apache_create_vhosts: true
        apache_vhosts_filename: "000-default.conf"
        apache_remove_default_vhost: true
        apache_vhosts:
          - servername: "wordpress"
            documentroot: "/var/www/html"
            extra_parameters: |
              <Directory "/var/www/html">
                  AllowOverride All
                  Options Indexes FollowSymLinks
                  Require all granted
              </Directory>
        
        php_packages:
          - php
          - php-cli
          - php-common
          - php-curl
          - php-gd
          - php-mbstring
          - php-mysqlnd
          - php-xml
          - php-zip
          - php-intl
          - php-json
          - php-opcache
        
        php_enable_php_fpm: false
        php_webserver_daemon: "httpd"
        php_enablerepo: ""

      tasks:
        - name: Install Apache and PHP
          include_role:
            name: geerlingguy.apache
        
        - name: Install PHP
          include_role:
            name: geerlingguy.php

        - name: Create WordPress directory
          file:
            path: /var/www/html
            state: directory
            owner: apache
            group: apache
            mode: '0755'

        - name: Download WordPress
          get_url:
            url: https://wordpress.org/latest.tar.gz
            dest: /tmp/wordpress.tar.gz

        - name: Extract WordPress
          unarchive:
            src: /tmp/wordpress.tar.gz
            dest: /tmp
            remote_src: yes

        - name: Copy WordPress files
          copy:
            src: /tmp/wordpress/
            dest: /var/www/html/
            owner: apache
            group: apache
            mode: preserve
            remote_src: yes

        - name: Set WordPress permissions
          file:
            path: /var/www/html
            owner: apache
            group: apache
            recurse: yes

        - name: Create wp-config.php from template
          template:
            src: /tmp/wp-config.php.j2
            dest: /var/www/html/wp-config.php
            owner: apache
            group: apache
            mode: '0644'

        - name: Download WP-CLI
          get_url:
            url: https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
            dest: /usr/local/bin/wp
            mode: '0755'

        - name: Get WordPress admin password from Parameter Store
          shell: aws ssm get-parameter --region ${region} --name "/${project_name}/${environment}/wordpress/admin_password" --with-decryption --query 'Parameter.Value' --output text
          register: wp_admin_password

        - name: Install WordPress core
          shell: |
            cd /var/www/html
            sudo -u apache /usr/local/bin/wp core install \
              --url="http://{{ ansible_default_ipv4.address }}" \
              --title="WordPress Geo Test - ${region}" \
              --admin_user="admin" \
              --admin_password="{{ wp_admin_password.stdout }}" \
              --admin_email="${admin_email}" \
              --allow-root
          register: wp_core_install
          ignore_errors: yes

        - name: Install Composer
          shell: |
            cd /tmp
            curl -sS https://getcomposer.org/installer | php
            mv composer.phar /usr/local/bin/composer
            chmod +x /usr/local/bin/composer

        - name: Install WP Offload Media Lite plugin
          shell: |
            cd /var/www/html
            sudo -u apache /usr/local/bin/wp plugin install amazon-s3-and-cloudfront --activate --allow-root
          ignore_errors: yes

        - name: Install and activate a free WordPress theme (Astra)
          shell: |
            cd /var/www/html
            sudo -u apache /usr/local/bin/wp theme install astra --activate --allow-root
          ignore_errors: yes

        - name: Install HyperDB plugin for database optimization
          shell: |
            cd /var/www/html
            wget -O /tmp/hyperdb.zip https://downloads.wordpress.org/plugin/hyperdb.zip
            unzip /tmp/hyperdb.zip -d /var/www/html/wp-content/plugins/
            chown -R apache:apache /var/www/html/wp-content/plugins/hyperdb
          ignore_errors: yes

        - name: Start and enable Apache
          systemd:
            name: httpd
            state: started
            enabled: yes

        - name: Wait for WordPress to be fully installed
          pause:
            seconds: 30

        - name: Reconfigure wp-config for regional read/write splitting
          template:
            src: /tmp/wp-config-optimized.php.j2
            dest: /var/www/html/wp-config.php
            owner: apache
            group: apache
            mode: '0644'
          when: wp_core_install is succeeded
    EOF

  # Create wp-config.php template
  - |
    cat <<'EOF' > /tmp/wp-config.php.j2
    <?php
    /**
     * WordPress configuration - Generated by Ansible
     */

    // Database settings - using Singapore primary for initial WordPress setup
    define( 'DB_NAME', '{{ db_name }}' );
    define( 'DB_USER', '{{ db_user }}' );
    define( 'DB_PASSWORD', '{{ db_password }}' );
    define( 'DB_HOST', '{{ db_host }}' );  // Singapore primary database
    define( 'DB_CHARSET', 'utf8mb4' );
    define( 'DB_COLLATE', '' );

    // WordPress table prefix
    $table_prefix = 'wp_';

    // WP Offload Media configuration
    {% if s3_bucket %}
    define( 'AS3CF_SETTINGS', serialize( array(
        'provider' => 'aws',
        'access-key-id' => '',
        'secret-access-key' => '',
        'use-server-roles' => true,
        'bucket' => '{{ s3_bucket }}',
        'region' => '${region}',
        'copy-to-s3' => true,
        'serve-from-s3' => true,
        'remove-local-file' => false,
        'object-versioning' => false,
    ) ) );
    {% endif %}

    // Note: HyperDB read/write splitting can be configured later after WordPress is installed
    // For now, all operations go to the Ireland primary database

    // WordPress debugging
    define( 'WP_DEBUG', false );
    define( 'WP_DEBUG_LOG', false );
    define( 'WP_DEBUG_DISPLAY', false );

    // WordPress URLs - using placeholder for now
    define( 'WP_HOME', 'http://{{ distribution_domain_name }}' );
    define( 'WP_SITEURL', 'http://{{ distribution_domain_name }}' );
    if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
     $_SERVER['HTTPS'] = 'on';
    }

    if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
     $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
    }
    // Disable file editing
    define( 'DISALLOW_FILE_EDIT', true );

    // Auto-update configuration
    define( 'WP_AUTO_UPDATE_CORE', true );

    /* That's all, stop editing! Happy publishing. */

    /** Absolute path to the WordPress directory. */
    if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
    }

    /** Sets up WordPress vars and included files. */
    require_once ABSPATH . 'wp-settings.php';
    EOF

  # Create optimized wp-config.php template for regional read/write splitting
  - |
    cat <<'EOF' > /tmp/wp-config-optimized.php.j2
    <?php
    /**
     * WordPress configuration - Optimized with read/write splitting
     */

    // Database settings - READ/WRITE SPLITTING
    define( 'DB_NAME', '{{ db_name }}' );
    define( 'DB_USER', '{{ db_user }}' );
    define( 'DB_PASSWORD', '{{ db_password }}' );
    
    // Write operations always go to Singapore primary
    define( 'DB_HOST_WRITE', '{{ lookup('aws_ssm', '${primary_db_endpoint_param}', region='ap-southeast-1') | regex_replace(':3306$', '') }}' );
    
    // Read operations use regional replica (local for better performance)
    define( 'DB_HOST', '{{ lookup('aws_ssm', '${db_endpoint_param}', region='${region}') | regex_replace(':3306$', '') }}' );
    
    define( 'DB_CHARSET', 'utf8mb4' );
    define( 'DB_COLLATE', '' );

    // WordPress table prefix
    $table_prefix = 'wp_';

    // WP Offload Media configuration
    {% if s3_bucket %}
    define( 'AS3CF_SETTINGS', serialize( array(
        'provider' => 'aws',
        'access-key-id' => '',
        'secret-access-key' => '',
        'use-server-roles' => true,
        'bucket' => '{{ s3_bucket }}',
        'region' => '${region}',
        'copy-to-s3' => true,
        'serve-from-s3' => true,
        'remove-local-file' => false,
        'object-versioning' => false,
    ) ) );
    {% endif %}

    // WordPress debugging
    define( 'WP_DEBUG', false );
    define( 'WP_DEBUG_LOG', false );
    define( 'WP_DEBUG_DISPLAY', false );

    // Disable file editing
    define( 'DISALLOW_FILE_EDIT', true );

    // Auto-update configuration
    define( 'WP_AUTO_UPDATE_CORE', true );

    /* That's all, stop editing! Happy publishing. */

    /** Absolute path to the WordPress directory. */
    if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
    }

    /** Sets up WordPress vars and included files. */
    require_once ABSPATH . 'wp-settings.php';
    EOF

  # Run the Ansible playbook
  - sudo -u ansible ANSIBLE_ROLES_PATH=/tmp/ansible/roles ansible-playbook /tmp/ansible/playbooks/wordpress.yml
