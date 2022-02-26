terraform {
  backend "gcs" {
    bucket      = "terraform-backend-tcc-bluechat"
    prefix      = "bluechat-terraform"
    credentials = "terraform.json"
  }
}