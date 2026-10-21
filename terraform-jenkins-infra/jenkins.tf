data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.jenkins_public.id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    exec > >(tee -a /var/log/jenkins-bootstrap.log) 2>&1

    apt-get update
    apt-get install -y fontconfig openjdk-21-jre curl

    install -d -m 0755 /etc/apt/keyrings

    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    -o /etc/apt/keyrings/jenkins-keyring.asc

    chmod 0644 /etc/apt/keyrings/jenkins-keyring.asc

    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

    apt-get update
    apt-get install -y jenkins

    systemctl enable --now jenkins

  USERDATA

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name      = "${var.project_name}-jenkins-server"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}