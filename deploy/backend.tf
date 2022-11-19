terraform {
  backend "s3" {
    bucket         = "recipe-app-tfstate-bucket2"
    key            = "recipe-app.tfstate"
    region         = "eu-west-3"
    encrypt        = true
    dynamodb_table = "recipe-app-tfstate-lock"
  }
}
