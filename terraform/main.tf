# ======================== DOKS ===========================
resource "digitalocean_kubernetes_cluster" "primary" {
  name    = var.doks_cluster_name
  region  = var.doks_cluster_region
  version = var.doks_cluster_version

  node_pool {
    name       = "${var.doks_cluster_name}-pool"
    size       = var.doks_cluster_pool_size
    node_count = var.doks_cluster_pool_node_count
  }
}

# ======================== ARGO ===========================
resource "kubectl_manifest" "namespace" {
    count     = length(data.kubectl_file_documents.namespace.documents)
    yaml_body = element(data.kubectl_file_documents.namespace.documents, count.index)
    override_namespace = "argocd"
}

resource "kubectl_manifest" "argocd" {
    depends_on = [
      kubectl_manifest.namespace,
    ]
    count     = length(data.kubectl_file_documents.argocd.documents)
    yaml_body = element(data.kubectl_file_documents.argocd.documents, count.index)
    override_namespace = "argocd"
}

resource "kubectl_manifest" "bluechat-app" {
    depends_on = [
      kubectl_manifest.argocd,
    ]
    count     = length(data.kubectl_file_documents.bluechat-app.documents)
    yaml_body = element(data.kubectl_file_documents.bluechat-app.documents, count.index)
    override_namespace = "argocd"
}

# ======================== K8S ===========================
#Secrets

resource "kubectl_manifest" "secrets-bluechat" {
  count     = length(data.kubectl_file_documents.secrets-bluechat.documents)
  yaml_body = element(data.kubectl_file_documents.secrets-bluechat.documents, count.index)
}