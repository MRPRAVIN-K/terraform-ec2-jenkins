# ============================================================
# IAM Role for Dynamic EC2
# ============================================================

resource "aws_iam_role" "dynamic_ec2_role" {
  name = "dynamic-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "dynamic-ec2-ecr-role"
    Project = "Jenkins-Terraform-Ansible"
    Managed = "Terraform"
  }
}

# ============================================================
# ECR Permissions
# ============================================================

resource "aws_iam_role_policy" "ecr_push_policy" {
  name = "dynamic-ec2-ecr-push-policy"
  role = aws_iam_role.dynamic_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer"
        ]

        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

# ============================================================
# EC2 Instance Profile
# ============================================================

resource "aws_iam_instance_profile" "dynamic_ec2_profile" {
  name = "dynamic-ec2-ecr-profile"
  role = aws_iam_role.dynamic_ec2_role.name
}
