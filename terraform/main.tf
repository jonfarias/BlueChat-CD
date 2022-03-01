# ============================== GCP ==============================

resource "google_service_account" "main" {
  account_id   = "${var.gcp_cluster_name}-id"
  display_name = "GKE Cluster ${var.gcp_cluster_name} Service Account"
}

resource "google_compute_network" "vpc" {
  name                    = "${var.gcp_cluster_name}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.gcp_cluster_name}-subnet"
  region        = var.gcp_region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gcp_cluster_ip
}

resource "google_container_cluster" "main" {
  name                     = "${var.gcp_cluster_name}-cluster"
  location                 = var.gcp_region
  remove_default_node_pool = true
  initial_node_count       = var.gcp_initial_node_count
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name

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
    preemptible     = true
    machine_type    = var.gcp_node_machine
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.main.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# ======================================================================

# ============================== GKE AUTH ==============================

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [google_container_cluster.main]
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

# ================================================================================

# ===================== Private Key for Linkerd (trustanchor) ====================

resource "tls_private_key" "trustanchor_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trustanchor_cert" {
  key_algorithm         = "${tls_private_key.trustanchor_key.algorithm}"
  private_key_pem       = "${tls_private_key.trustanchor_key.private_key_pem}"
  validity_period_hours = 87600
  is_ca_certificate     = true

  subject {
    common_name = "identity.linkerd.cluster.local"
  }

  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}

#===================================================================================

# ===================== Private Key for Linkerd (issuer key) =======================

resource "tls_private_key" "issuer_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer_req" {
  key_algorithm   = "${tls_private_key.issuer_key.algorithm}"
  private_key_pem = "${tls_private_key.issuer_key.private_key_pem}"

  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer_cert" {
  cert_request_pem      = "${tls_cert_request.issuer_req.cert_request_pem}"
  ca_key_algorithm      = "${tls_private_key.trustanchor_key.algorithm}"
  ca_private_key_pem    = "${tls_private_key.trustanchor_key.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.trustanchor_cert.cert_pem}"
  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "crl_signing",
    "cert_signing",
    "server_auth",
    "client_auth"
  ]
}

# =============================================================================

# ===================================== HELM ==================================

resource "helm_release" "ingress-nginx" {
  depends_on       = [google_container_node_pool.main]
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.17"
  create_namespace = true
  namespace        = "ingress-nginx"

  set{
    name = "controller.metrics.enabled"
    value = true
  }
}

resource "helm_release" "argocd" {
  depends_on       = [helm_release.ingress-nginx]
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "3.33.8"
  create_namespace = true
  namespace        = "argocd"
}

resource "helm_release" "prometheus" {
  depends_on       = [helm_release.ingress-nginx]
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "33.1.0"
  create_namespace = true
  namespace        = "monitoring"
}

resource "helm_release" "linkerd" {
  depends_on       = [helm_release.prometheus]
  name             = "linkerd"
  repository       = "https://helm.linkerd.io/stable"
  chart            = "linkerd2"
  version          = "2.11.1"

  set {
    name  = "identityTrustAnchorsPEM"
    value = tls_self_signed_cert.trustanchor_cert.cert_pem
  }

  set {
    name  = "identity.issuer.crtExpiry"
    value = tls_locally_signed_cert.issuer_cert.validity_end_time
  }

  set {
    name  = "identity.issuer.tls.crtPEM"
    value = tls_locally_signed_cert.issuer_cert.cert_pem
  }

  set {
    name  = "identity.issuer.tls.keyPEM"
    value = tls_private_key.issuer_key.private_key_pem
  }
}


#resource "helm_release" "cert-manager" {
#  name  = "cert-manager"
#  repository = "https://charts.jetstack.io"
#  chart      = "cert-manager"
#  version    = "1.7.1"
#}

# =====================================================================

# ============================== kubectl ==============================

resource "kubectl_manifest" "namespace-bluechat-prod" {
  depends_on = [google_container_node_pool.main]
  count      = length(data.kubectl_file_documents.namespace-bluechat-prod.documents)
  yaml_body  = element(data.kubectl_file_documents.namespace-bluechat-prod.documents, count.index)
}

resource "kubectl_manifest" "bluechat-app-prod" {
  depends_on = [helm_release.argocd]
  count      = length(data.kubectl_file_documents.bluechat-app-prod.documents)
  yaml_body  = element(data.kubectl_file_documents.bluechat-app-prod.documents, count.index)
}

resource "kubectl_manifest" "secrets-bluechat-prod" {
  depends_on = [kubectl_manifest.namespace-bluechat-prod]
  count      = length(data.kubectl_file_documents.secrets-bluechat-prod.documents)
  yaml_body  = element(data.kubectl_file_documents.secrets-bluechat-prod.documents, count.index)
}

resource "kubectl_manifest" "ingress-bluechat-prod" {
  depends_on = [helm_release.ingress-nginx]
  count      = length(data.kubectl_file_documents.ingress-bluechat-prod.documents)
  yaml_body  = element(data.kubectl_file_documents.ingress-bluechat-prod.documents, count.index)
}

resource "kubectl_manifest" "namespace-bluechat-dev" {
  depends_on = [google_container_node_pool.main]
  count      = length(data.kubectl_file_documents.namespace-bluechat-dev.documents)
  yaml_body  = element(data.kubectl_file_documents.namespace-bluechat-dev.documents, count.index)
}

resource "kubectl_manifest" "bluechat-app-dev" {
  depends_on = [helm_release.argocd]
  count      = length(data.kubectl_file_documents.bluechat-app-dev.documents)
  yaml_body  = element(data.kubectl_file_documents.bluechat-app-dev.documents, count.index)
}

resource "kubectl_manifest" "secrets-bluechat-dev" {
  depends_on = [kubectl_manifest.namespace-bluechat-dev]
  count      = length(data.kubectl_file_documents.secrets-bluechat-dev.documents)
  yaml_body  = element(data.kubectl_file_documents.secrets-bluechat-dev.documents, count.index)
}

resource "kubectl_manifest" "ingress-bluechat-dev" {
  depends_on = [helm_release.ingress-nginx]
  count      = length(data.kubectl_file_documents.ingress-bluechat-dev.documents)
  yaml_body  = element(data.kubectl_file_documents.ingress-bluechat-dev.documents, count.index)
}

resource "kubectl_manifest" "ingress-argocd" {
  depends_on = [helm_release.argocd]
  count      = length(data.kubectl_file_documents.ingress-argocd.documents)
  yaml_body  = element(data.kubectl_file_documents.ingress-argocd.documents, count.index)
}

resource "kubectl_manifest" "ingress-grafana" {
  depends_on = [helm_release.prometheus]
  count      = length(data.kubectl_file_documents.ingress-grafana.documents)
  yaml_body  = element(data.kubectl_file_documents.ingress-grafana.documents, count.index)
}

resource "kubectl_manifest" "ingress-prometheus" {
  depends_on = [helm_release.prometheus]
  count      = length(data.kubectl_file_documents.ingress-prometheus.documents)
  yaml_body  = element(data.kubectl_file_documents.ingress-prometheus.documents, count.index)
}