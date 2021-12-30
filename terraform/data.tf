# ======================== DOKS ===========================
data "digitalocean_kubernetes_cluster" "primary" {
  name = var.doks_cluster_name
  depends_on = [
    digitalocean_kubernetes_cluster.primary
  ]
}

# ======================== ARGO ===========================

data "kubectl_file_documents" "namespace" {
    content = file("../manifests/argocd/namespace.yml")
} 

data "kubectl_file_documents" "argocd" {
    content = file("../manifests/argocd/install.yml")
}

data "kubectl_file_documents" "bluechat-app" {
    content = file("../manifests/argocd/bluechat-argocd.yml")
}

data "kubectl_file_documents" "secrets-bluechat"{
    content = file("../manifests/bluechat/secret-bluechat.yml")
}