#set aws provider
provider "aws" {
  profile = var.profile
  region = var.region
}
#set the backend for state file
#terraform {
#  backend "s3" {
#    bucket = "aws-etl-demo-bucket"
#    key = "resources/terraform.tfstate"
#    workspace_key_prefix = "env"
#    region = "us-east-1"
#    encrypt = true
#  }
#}



