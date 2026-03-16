# terraform/environments/dev/backend.tf

terraform {
  backend "s3" {
    key     = "environments/dev/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
    # bucket and dynamodb_table will be passed in via CLI/Config file
  }
}