terraform {
  backend "gcs" {
    bucket = "terraform-backend-bluechat-04012022"
    prefix = "bluechat-terraform"
    credentials = "terraform-deploy.json"
  }
}