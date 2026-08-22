output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.server.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.server.public_ip
}

output "public_dns" {
  description = "EC2 public DNS"
  value       = aws_instance.server.public_dns
}

output "private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.server.private_ip
}

output "ami_id" {
  description = "Ubuntu AMI ID"
  value       = data.aws_ami.ubuntu.id
}
