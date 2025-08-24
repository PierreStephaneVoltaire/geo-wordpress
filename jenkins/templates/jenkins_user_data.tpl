#cloud-config
# Terraform template file - variables: random_suffix, region
package_update: true
package_upgrade: true

packages:
  - java-17-amazon-corretto-devel
  - git
  - python3
  - python3-pip
  - unzip
  - wget
  - ansible

runcmd:
  - systemctl enable amazon-ssm-agent
  - systemctl start amazon-ssm-agent
  - useradd -m -s /bin/bash ansible
  - usermod -aG wheel ansible
  - echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
  - mkdir -p /tmp/roles
  - ansible-galaxy install geerlingguy.jenkins geerlingguy.java --force --roles-path /tmp/roles
  - |
    cat <<'EOF' > /tmp/playbook.yml
    - hosts: localhost
      connection: local
      become: yes
      gather_facts: yes
      vars:
        java_packages:
          - java-17-amazon-corretto-devel
        jenkins_hostname: localhost
        jenkins_http_port: 8080
        jenkins_admin_username: "{{ lookup('aws_ssm', '/jenkins/admin/username-${random_suffix}', region='${region}') }}"
        jenkins_admin_password: "{{ lookup('aws_ssm', '/jenkins/admin/password-${random_suffix}', region='${region}') }}"
        jenkins_java_options: "-Djenkins.install.runSetupWizard=false -Djava.io.tmpdir=/opt/jenkins/tmp -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Duser.country=US -Duser.language=en -Djava.security.egd=file:/dev/./urandom"
        jenkins_plugins:
          - build-timeout
          - credentials-binding
          - timestamper
          - ws-cleanup
          - ant
          - gradle
          - workflow-aggregator
          - pipeline-stage-view
          - git
          - github-branch-source
          - ssh-slaves
      pre_tasks:
        - name: Create Jenkins base directory (world-writable)
          file:
            path: /opt/jenkins
            state: directory
            mode: '0777'
          become: yes

        - name: Create Jenkins temp directory (world-writable)
          file:
            path: /opt/jenkins/tmp
            state: directory
            mode: '0777'
          become: yes
         
      roles:
        - geerlingguy.java
        - geerlingguy.jenkins
      post_tasks:
        - name: Install Terraform
          shell: |
            cd /tmp
            wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
            unzip terraform_1.5.7_linux_amd64.zip
            mv terraform /usr/local/bin/
            chmod +x /usr/local/bin/terraform
            rm -f terraform_1.5.7_linux_amd64.zip
          args:
            creates: /usr/local/bin/terraform
          become: yes
        
        - name: Create Jenkins workspace directory (world-writable)
          file:
            path: /var/lib/jenkins-workspace
            state: directory
            mode: '0777'
          become: yes  
    EOF
  - sudo -u ansible ANSIBLE_ROLES_PATH=/tmp/roles ansible-playbook /tmp/playbook.yml