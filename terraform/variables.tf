# ===================== GCP ========================
variable "gcp_project_id" {
  type    = string
  default = "bluechat-04012022"
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-c"
}

variable "gcp_cluster_name" {
  type    = string
  default = "bluechat"
}

variable "gcp_node_machine" {
  type    = string
  default = "e2-small"
}

variable "gcp_initial_node_count" {
  type    = number
  default = 1
}

variable "gcp_node_count" {
  type    = number
  default = 2
}
