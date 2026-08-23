terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# Latest Ubuntu 24.04 LTS AMI
# ============================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

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

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# Default VPC
# ============================================================

data "aws_vpc" "default" {
  default = true
}

# ============================================================
# Default Subnets
# ============================================================

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================
# Security Group
# ============================================================

resource "aws_security_group" "jenkins_created_server" {
  name_prefix = "jenkins-created-server-sg-"
  description = "Security group for EC2 created by Jenkins and Terraform"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application / Docker testing
  ingress {
    description = "Application Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "jenkins-created-server-sg"
    Project = "Jenkins-Terraform-Ansible"
  }
}

# ============================================================
# EC2 Instance
# ============================================================

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.default.ids[0]

  # Existing AWS key pair
  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.jenkins_created_server.id
  ]

  root_block_device {
    volume_type = "gp3"
    volume_size = 35
  }

  tags = {
    Name    = "jenkins-created-server"
    Project = "Jenkins-Terraform-Ansible"
    Managed = "Terraform"
  }
}
