variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "Ogust-26"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the EC2 server"
  type        = string
  default     = "0.0.0.0/0"
}
