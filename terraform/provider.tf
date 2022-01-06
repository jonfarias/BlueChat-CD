terraform {
  required_version = ">= 1.1.2"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13.1"
    }
  }
  backend "gcs" {
    bucket = "terraform-backend-bluechat-04012022"
    prefix = "bluechat-terraform"
  }
}

provider "google" {
  #credentials = "${file("bluechat-04012022-26411bc00a7e.json")}"
  project     = var.gcp_project_id
  region      = var.gcp_region
  zone        = var.gcp_zone
}

provider "kubernetes" {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  load_config_file       = false
}

provider "kubectl" {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
    #exec {
    #  api_version = "client.authentication.k8s.io/v1alpha1"
    #  args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    #  command     = "aws"
    #}
  }
}