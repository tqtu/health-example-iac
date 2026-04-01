terraform {
  backend "s3" {
    bucket         = "unboundshare-infra-storage-31-03-2026-1"
    key            = "environments/production-compute/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}