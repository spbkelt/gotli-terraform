variable "ssh_key_name" {}

variable "vpc_security_group_ids" {
  type = "list"
}

variable "aws_ami" {}

variable "aws_subnet_public_id" {}

variable "aws_region" {}
