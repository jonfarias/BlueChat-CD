data "google_container_cluster" "main" {
  name     = var.gcp_cluster_name
  location = var.gcp_region
  depends_on = [google_container_cluster.main]
}

data "google_client_config" "main" {
    depends_on = [google_container_cluster.main]
}

# ======================== Kubectl ===========================

data "kubectl_file_documents" "bluechat-app" {
    content = file("../manifests/argocd/bluechat-argocd.yml")
}

data "kubectl_file_documents" "secrets-bluechat"{
    content = file("../manifests/bluechat-prod/secret-bluechat.yml")
}

data "kubectl_file_documents" "ingress-bluechat"{
    content = file("../manifests/bluechat-prod/ingress/ingress_bluechat.yml")
}

data "kubectl_file_documents" "ingress-argocd"{
    content = file("../manifests/bluechat-prod/ingress/ingress_argocd.yml")
}