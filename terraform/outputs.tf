output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.server.public_dns
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.server.id
}

output "ami_id" {
  description = "Ubuntu AMI ID"
  value       = data.aws_ami.ubuntu.id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.server.private_ip
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}
