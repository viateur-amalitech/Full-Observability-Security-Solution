terraform {
  backend "s3" {
    bucket         = "fullobservability"
    key            = "state/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
