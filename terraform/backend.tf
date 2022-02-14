terraform {
  backend "gcs" {
    bucket = "terraform-backend-<project-id>"
    prefix = "bluechat-terraform"
    credentials = "terraform-deploy.json"
  }
}