variable "is_kube_api_healthy" {}

variable "kube_api_url" {}

variable "nodes_count" {}

variable "service_dns_ip" {}

variable "kubernetes_version" {}

variable "ssh_key_name" {}

variable "aws_ami" {}

variable "vpc_security_group_ids" { type = "list"}

variable "aws_subnet_private_id" {}

variable "aws_region" {}

variable "bastion_host" {}

variable "ssh_private_key_path" {}

variable "secret_kubelet_token" {}

variable "secret_kubeproxy_token" {}

variable "cni_plugin_version" {}

variable "instance_type" {}

variable "aws_zone" {}

variable "db_user" {}

variable "db_password" {}
