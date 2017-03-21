variable "is_kube_api_healthy" {}

variable "federation_control_plane_manifest" {}

variable "aws_public_zone" {}

variable "kubernetes_version" {}

variable "k8s_master_private_ips" { type ="list"}

variable "k8s_master_instance_ids" {type ="list"}

variable "bastion_host" {}

variable "ssh_private_key_path" {}

variable "k8s_master_ip" {}
