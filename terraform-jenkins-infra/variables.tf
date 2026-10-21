variable "aws_region" {
  description = "AWS region for Jenkins infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project resource name prefix"
  type        = string
  default     = "devops-capstone"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated Jenkins VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Jenkins public subnet"
  type        = string
  default     = "10.30.1.0/24"
}

variable "admin_cidr" {
  description = "Your public IP address in CIDR notation"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && endswith(var.admin_cidr, "/32")
    error_message = "Provide your public IPv4 address with /32, for example 203.0.113.10/32."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "m7i-flex.large"
}