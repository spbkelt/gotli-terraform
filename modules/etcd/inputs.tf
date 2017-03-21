variable "bastion_ip" {}

variable "nodes_count" {
  default = "3"
}

variable "ssh_key_name" {}

variable "vpc_security_group_ids" {
  type = "list"
}

variable "discovery_url" {
  description = "etcd bootstrap discovery url"
}

variable "aws_ami" {}

variable "aws_subnet_private_id" {}

variable "aws_region" {}
