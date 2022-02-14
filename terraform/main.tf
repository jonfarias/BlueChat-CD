# ============================== GCP ==============================

resource "google_service_account" "main" {
  account_id   = "${var.gcp_cluster_name}-id"
  display_name = "GKE Cluster ${var.gcp_cluster_name} Service Account"
}

resource "google_container_cluster" "main" {
  name     = "${var.gcp_cluster_name}-cluster"
  location = var.gcp_region
  remove_default_node_pool = true
  initial_node_count       = var.gcp_initial_node_count

  release_channel {
    channel = "STABLE"
  }
}

resource "google_container_node_pool" "main" {
  name       = "${var.gcp_cluster_name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.main.name
  node_count = var.gcp_node_count

  node_config {
    preemptible  = true
    machine_type = var.gcp_node_machine
    image_type   = "COS_CONTAINERD"
    service_account = google_service_account.main.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# ======================================================================

# ============================== GKE AUTH ==============================

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_container_cluster.main]
  create_duration = "30s"
}

module "gke_auth" {
  depends_on           = [time_sleep.wait_30_seconds]
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id           = var.gcp_project_id
  cluster_name         = google_container_cluster.main.name
  location             = var.gcp_region
  use_private_endpoint = false
}

# ==================================================================

# ============================== HELM ==============================

resource "helm_release" "ingress-nginx" {
  name  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.0.13"
  create_namespace = true
  namespace  = "ingress-nginx"
}

resource "helm_release" "argocd" {
  depends_on = [helm_release.ingress-nginx]
  name  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.29.5"
  create_namespace = true
  namespace  = "argocd"
}

resource "helm_release" "prometheus" {
  depends_on = [helm_release.ingress-nginx]
  name  = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "12.8.0"
  create_namespace = true
  namespace  = "monitoring"
}

#resource "helm_release" "cert-manager" {
#  name  = "cert-manager"
#  repository = "https://charts.jetstack.io"
#  chart      = "cert-manager"
#  version    = "1.6.1"
#}

# =====================================================================

# ============================== kubectl ==============================

resource "kubectl_manifest" "namespace-bluechat-prod" {
  count     = length(data.kubectl_file_documents.namespace-bluechat-prod.documents)
  yaml_body = element(data.kubectl_file_documents.namespace-bluechat-prod.documents, count.index)
}

resource "kubectl_manifest" "bluechat-app" {
    depends_on = [helm_release.argocd]
    count     = length(data.kubectl_file_documents.bluechat-app.documents)
    yaml_body = element(data.kubectl_file_documents.bluechat-app.documents, count.index)
}

resource "kubectl_manifest" "ingress-argocd" {
  depends_on = [helm_release.argocd]
  count     = length(data.kubectl_file_documents.ingress-argocd.documents)
  yaml_body = element(data.kubectl_file_documents.ingress-argocd.documents, count.index)
}


resource "kubectl_manifest" "secrets-bluechat" {
  depends_on = [kubectl_manifest.namespace-bluechat-prod]
  count     = length(data.kubectl_file_documents.secrets-bluechat.documents)
  yaml_body = element(data.kubectl_file_documents.secrets-bluechat.documents, count.index)
}

resource "kubectl_manifest" "ingress-bluechat" {
  depends_on = [helm_release.ingress-nginx]
  count     = length(data.kubectl_file_documents.ingress-bluechat.documents)
  yaml_body = element(data.kubectl_file_documents.ingress-bluechat.documents, count.index)
}

resource "kubectl_manifest" "prometheus" {
  depends_on = [helm_release.prometheus]
  count     = length(data.kubectl_file_documents.prometheus.documents)
  yaml_body = element(data.kubectl_file_documents.prometheus.documents, count.index)
}
