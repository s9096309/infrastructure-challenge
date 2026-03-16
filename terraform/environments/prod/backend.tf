# terraform/environments/prod/backend.tf

terraform {
  backend "s3" {
    # Using same bucket and lock table, but a strictly isolated state file path
    bucket         = "fincite-pumpkin-tf-state-<YOUR_ACCOUNT_ID>"
    key            = "environments/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "fincite-pumpkin-tf-locks"
    encrypt        = true
  }
}