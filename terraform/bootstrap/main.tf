# terraform/bootstrap/main.tf

provider "aws" {
  region = "eu-central-1"
}

# --- S3 Bucket for State ---
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "fincite-pumpkin-tf-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Only for assignment to easily clean up later
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- DynamoDB Table for Locking ---
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "fincite-pumpkin-tf-locks"
  billing_mode = "PAY_PER_REQUEST" # Cost optimization: only pay for what you use
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

data "aws_caller_identity" "current" {}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}