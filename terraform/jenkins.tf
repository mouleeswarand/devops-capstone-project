# Security group for the new Terraform-managed Jenkins server.
resource "aws_security_group" "jenkins" {
  name_prefix = "${var.project_name}-jenkins-"
  description = "Restricted access for the capstone Jenkins server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["157.51.88.214/32"]
  }

  ingress {
    description = "Jenkins web UI from the workstation"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["157.51.88.214/32"]
  }

  egress {
    description = "Outbound access for package installation and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-jenkins-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Fresh Jenkins server in the existing capstone VPC.
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "m7i-flex.large"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  key_name                    = "capstone"
  iam_instance_profile        = "devops-capstone-jenkins-role"

  user_data                   = file("${path.module}/jenkins-user-data.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-jenkins"
    Role = "CI-CD"
  })
}

output "jenkins_instance_id" {
  description = "Instance ID of the new Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of the new Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL; accessible only from the allowed workstation IP"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
