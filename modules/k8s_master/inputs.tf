variable "is_etcd_healthy" {}

variable "nodes_count" {}

variable "service_dns_ip" {}

variable "cluster_service_cidr" {}

variable "kubernetes_version" {}

variable "ssh_key_name" {}

variable "ssh_private_key_path" {}

variable "aws_ami" {}

variable "vpc_security_group_ids" { type = "list"}

variable "aws_subnet_private_id" {}

variable "etcd_elb_url" {}

variable "service_api_ip" {}

variable "cni_plugin_version" {}

variable "aws_region" {}

variable "aws_kms_key_arn" {}

variable "bastion_host" {}

variable "kubedns_addon_manifest" {}

variable "weave_init_addon_manifest" {}

variable "weave_version" {}

variable "weavenet_cidr" {}

variable "weave_password" {}

variable "kubedns_version" {}
