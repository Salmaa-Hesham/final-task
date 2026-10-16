terraform {
  backend "s3" {
    bucket  = "salma-realworld-tfstate-253650698585"
    key     = "demo/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
