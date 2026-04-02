# 1. Base Repository (Optional - you can keep this if you use it for other things)
resource "aws_ecr_repository" "docker_repo" {
  name                 = "unboundshare"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "global"
    Project     = "unboundshare"
  }
}

# 2. Environment Specific Repositories (The ones your GitHub Action needs)
variable "environments" {
  type    = list(string)
  default = ["qa", "staging", "production"]
}

resource "aws_ecr_repository" "backend_repos" {
  for_each = toset(var.environments)

  name                 = "unboundshare/${each.value}/hello-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 3. Apply Lifecycle Policy to ALL new repositories
resource "aws_ecr_lifecycle_policy" "backend_repo_policy" {
  for_each   = aws_ecr_repository.backend_repos # This links the policy to all 3 repos
  repository = each.value.name

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

# 4. Updated Output (To see your new URLs)
output "ecr_origin" {
  # This splits the URL by '/' and takes the first part (the domain)
  value       = split("/", aws_ecr_repository.docker_repo.repository_url)[0]
  description = "The ECR Registry Origin (Account ID and Region)"
}