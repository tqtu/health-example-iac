provider "aws" { region = "ap-southeast-2" }

resource "aws_s3_bucket" "terraform_state" {
  bucket = "luca-terraform-state-storage-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID", type = "S" }
}

resource "random_id" "suffix" { byte_length = 4 }
