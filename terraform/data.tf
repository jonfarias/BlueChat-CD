data "google_container_cluster" "main" {
  name       = var.gcp_cluster_name
  location   = var.gcp_region
  depends_on = [google_container_cluster.main]
}

data "google_client_config" "main" {
  depends_on = [google_container_cluster.main]
}

# ======================== Kubectl ===========================

#ArgoCD-DEV
data "kubectl_file_documents" "bluechat-app-prod" {
  content = file("../manifests/argocd/argocd-bluechat-prod.yml")
}
#Namespace BlueChat-PROD
data "kubectl_file_documents" "namespace-bluechat-prod" {
  content = file("../manifests/bluechat-prod/name-blue-prod.yml")
}
#Secrets BlueChat-PROD
data "kubectl_file_documents" "secrets-bluechat-prod" {
  content = file("../manifests/bluechat-prod/bluechat-secret-prod.yml")
}
#Ingress PROD
#data "kubectl_file_documents" "ingress-bluechat-prod" {
#  content = file("../manifests/bluechat-prod/bluechat-ingress-prod.yml")
#}


#ArgoCD-DEV
data "kubectl_file_documents" "bluechat-app-dev" {
  content = file("../manifests/argocd/argocd-bluechat-dev.yml")
}
#Namespace BlueChat-DEV
data "kubectl_file_documents" "namespace-bluechat-dev" {
  content = file("../manifests/bluechat-dev/name-blue-dev.yml")
}
#Secrets BlueChat-DEV
data "kubectl_file_documents" "secrets-bluechat-dev" {
  content = file("../manifests/bluechat-dev/bluechat-secret-dev.yml")
}
#Ingress DEV
#data "kubectl_file_documents" "ingress-bluechat-dev" {
#  content = file("../manifests/bluechat-dev/bluechat-ingress-dev.yml")
#}

data "kubectl_file_documents" "ingress-argocd" {
  content = file("../manifests/ingress-nginx/argocd-ingress.yml")
}

data "kubectl_file_documents" "ingress-grafana" {
  content = file("../manifests/ingress-nginx/grafana-ingress.yml")
}

data "kubectl_file_documents" "ingress-prometheus" {
  content = file("../manifests/ingress-nginx/prometheus-ingress.yml")
}