terraform {
  backend "s3" {
    bucket         = "prod-terraform-state-bucket-base-take-home"
    key            = "welcome/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "prod-terraform-locks"
    encrypt        = true
  }
}
