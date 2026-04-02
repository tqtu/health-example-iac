resource "aws_ecr_repository" "docker_repo" {
  name                 = "unboundshare"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "global"
    Project     = "unboundshare"
  }
}

# Separate lifecycle policy
resource "aws_ecr_lifecycle_policy" "docker_repo_policy" {
  repository = aws_ecr_repository.docker_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection    = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "ecr_uri" {
  value       = aws_ecr_repository.docker_repo.repository_url
  description = "AWS ECR repository URI for backend Docker images"
}