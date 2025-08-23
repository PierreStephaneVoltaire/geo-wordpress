data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "random_password" "jenkins_admin_password" {
  length  = 16
  special = true
}


resource "aws_ssm_parameter" "jenkins_admin_username" {
  name  = "/jenkins/admin/username-${random_id.suffix.hex}"
  type  = "String"
  value = "admin"

  tags = {
    Name = "jenkins-admin-username-${random_id.suffix.hex}"
  }
}

resource "aws_ssm_parameter" "jenkins_admin_password" {
  name  = "/jenkins/admin/password-${random_id.suffix.hex}"
  type  = "SecureString"
  value = random_password.jenkins_admin_password.result

  tags = {
    Name = "jenkins-admin-password-${random_id.suffix.hex}"
  }
}

resource "aws_instance" "jenkins" {
  tags                        = { "Name" = "jenkins-ec2-${random_id.suffix.hex}" }
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  monitoring                  = false
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  user_data = <<-EOF
#cloud-config
package_update: true
package_upgrade: true

packages:
  - java-17-amazon-corretto-devel
  - git
  - python3
  - python3-pip
  - unzip
  - wget
  - curl
  - amazon-ssm-agent

mounts:
  - [ tmpfs, /tmp, tmpfs, "defaults,size=4G", "0", "0" ]

runcmd:
  # Enable and start SSM agent
  - systemctl enable amazon-ssm-agent
  - systemctl start amazon-ssm-agent
  
  # Fix curl package conflict on Amazon Linux 2023
  - rpm -e --nodeps curl-minimal || true
  - dnf install -y curl --allowerasing
  
  # Create ansible user
  - useradd -m -s /bin/bash ansible
  - usermod -aG wheel ansible
  - echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
  
  # Install Ansible
  - pip3 install ansible

ansible:
  install_method: pip
  package_name: ansible
  run_user: ansible
  galaxy:
    actions: 
      - ['ansible-galaxy', 'collection', 'install', 'community.general:>=8.0.0', 'ansible.posix:>=1.5.0', '--force']
      - ['ansible-galaxy', 'install', 'geerlingguy.jenkins:4.3.0', 'geerlingguy.java:2.2.0', '--force']
  setup_controller:
    run_ansible:
      - hosts: localhost
        connection: local
        become: yes
        gather_facts: yes
        vars:
          java_packages:
            - java-17-amazon-corretto-devel
          jenkins_hostname: localhost
          jenkins_http_port: 8080
          jenkins_admin_username: "{{ lookup('aws_ssm', '/jenkins/admin/username-${random_id.suffix.hex}', region='${data.aws_region.current.name}') }}"
          jenkins_admin_password: "{{ lookup('aws_ssm', '/jenkins/admin/password-${random_id.suffix.hex}', region='${data.aws_region.current.name}') }}"
          jenkins_java_options: "-Djenkins.install.runSetupWizard=false -Djava.io.tmpdir=/var/lib/jenkins/tmp -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Duser.country=US -Duser.language=en -Djava.security.egd=file:/dev/./urandom"
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
          - name: Create Jenkins temp directory
            file:
              path: /var/lib/jenkins/tmp
              state: directory
              owner: jenkins
              group: jenkins
              mode: '0755'
            become: yes
            ignore_errors: yes
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
          - name: Download AWS CLI v2
            get_url:
              url: "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
              dest: "/tmp/awscliv2.zip"
            become: yes
          - name: Extract and install AWS CLI
            shell: |
              cd /tmp
              unzip -o awscliv2.zip
              ./aws/install --update
              rm -rf aws awscliv2.zip
            args:
              creates: /usr/local/bin/aws
            become: yes
          - name: Create Jenkins workspace directory
            file:
              path: /var/lib/jenkins-workspace
              state: directory
              owner: jenkins
              group: jenkins
              mode: '0755'
            become: yes
        timeout: 3600

final_message: |
  Jenkins CI/CD server setup completed!
  Jenkins will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
  
  Credentials are stored in AWS Parameter Store:
  - Username: $(aws ssm get-parameter --name "/jenkins/admin/username-${random_id.suffix.hex}" --query "Parameter.Value" --output text --region ${data.aws_region.current.name})
  - Password: $(aws ssm get-parameter --name "/jenkins/admin/password-${random_id.suffix.hex}" --with-decryption --query "Parameter.Value" --output text --region ${data.aws_region.current.name})
  
  Please change the admin password after first login!
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
}
