# Provider configuration for AWS
provider "aws" {
  region = "ap-southeast-2"
}

# Generate a random ID to ensure global uniqueness for the S3 bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket to store the Terraform Remote State file (.tfstate)
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "luca-terraform-state-storage-${random_id.suffix.hex}"

  # Prevent accidental deletion of this bucket
  # Set to 'true' only for temporary testing environments
  force_destroy = false

  tags = {
    Name        = "Terraform State Storage"
    ManagedBy   = "Terraform"
    Project     = "Health-Example"
  }
}

# Enable versioning so we can roll back to previous state files if needed
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default for security compliance
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for state locking to prevent concurrent operations
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  # LockID is required by Terraform to manage the lease
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locking"
    ManagedBy   = "Terraform"
  }
}

# Output the bucket name so it can be used in the backend configuration
output "terraform_state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "The name of the S3 bucket to be used in backend.tf"
}