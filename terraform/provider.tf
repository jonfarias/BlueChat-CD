terraform {
  required_version = ">= 1.1.2"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13.1"
    }
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
  #load_config_file       = true
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
  }
}