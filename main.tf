provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-webserver"
    key    = "state/terraform_state.tfstate"
    region = "eu-central-1"
  }
}
