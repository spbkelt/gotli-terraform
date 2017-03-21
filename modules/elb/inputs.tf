
variable "elb_name" {}

variable "aws_instances" {
  type = "list"
}

variable "is_internal" {}

variable "subnets" {
  type = "list"
}

variable "security_groups" {
  type = "list"
}

variable "instance_port" {}
variable "lb_port" {}

variable "instance_protocol" {}
variable "lb_protocol" {}

variable "health_check_target" {}

variable "aws_region" {}

variable "schema" {}

variable "health_uri_suffix" {}

variable "auth_token" {}

variable "aws_instance_private_ips" {
  type = "list"
}

variable "ssh_private_key_path" {}

variable "bastion_host" {}
