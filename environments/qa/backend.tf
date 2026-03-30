# terraform {
#   backend "s3" {
#     bucket         = "YOUR_BUCKET_NAME_FROM_BOOTSTRAP"
#     key            = "environments/qa/terraform.tfstate"
#     region         = "ap-southeast-2"
#     dynamodb_table = "terraform-state-locking"
#   }
# }
