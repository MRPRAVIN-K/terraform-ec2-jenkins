output "instance_ip" {
  description = "Public IP address of the Jenkins-created EC2 instance"
  value       = aws_instance.server.public_ip
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}
