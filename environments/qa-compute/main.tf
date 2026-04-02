# =========================
# 1. PROVIDER (Clean version)
# =========================
terraform {
  required_version = ">= 1.0"
}

# =========================
# 2. REMOTE STATE (The Bridge)
# =========================
data "terraform_remote_state" "qa_core" {
  backend = "s3"
  config = {
    bucket = "unboundshare-infra-storage-31-03-2026-1"
    key    = "environments/qa/terraform.tfstate"
    region = "ap-southeast-2"
  }
}