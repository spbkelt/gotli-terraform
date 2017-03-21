variable "aws_access_key" {}

variable "aws_secret_key"{}

variable "ssh_public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "ssh_private_key_path" {
  description = <<DESCRIPTION
Path to the SSH private key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.key
DESCRIPTION
}

variable "ssh_key_name" {
  description = "Desired name of AWS key pair"
}

variable "discovery_url" { }

variable "aws_region" {
  description = "AWS region to launch servers."
}

variable "deployment_iam_role_arn" {
  default = "arn:aws:iam::740380980326:role/kubernetes"
}

variable "deployment_iam_user_arn" {
  default = "arn:aws:iam::740380980326:user/Terraform"
}

# CoreOS-stable-1298.6.0-hvm
variable "aws_amis" {
  default = {
    us-east-1 = "ami-55339d43"
    eu-central-1 = "ami-113df07e"
    us-east-2 = "ami-72032617"

  }
}

variable "azs" {
  description = "Run the EC2 Instances in these Availability Zones"
  default = ["us-east-1a", "us-east-1b", "us-east-1c","us-east-1d","us-east-1e"]
}

variable "aws_regions_ecr_image_map" {
  default = {
    eu-central-1 = "740380980326.dkr.ecr.eu-central-1.amazonaws.com/gotli:1.0.0"
    us-east-2 = "740380980326.dkr.ecr.us-east-2.amazonaws.com/gotli:1.0.0"
    us-east-1 = "740380980326.dkr.ecr.us-east-1.amazonaws.com/gotli:1.0.0"
  }
  type = "map"
}

variable "etcd_nodes_count" { default = "3"}

variable "master_nodes_count" { default = "2"}

variable "worker_nodes_count" { default = "1"}

variable "db_nodes_count" { default = "1"}

variable "service_dns_ip" { default = "10.3.0.10"}

variable "service_api_ip" { default = "10.3.0.1"}

variable "cluster_service_cidr" {default = "10.3.0.0/24"}

variable "kubernetes_version" {default = "1.5.4"}

variable "cni_plugin_version" { default = "0.4.0" }

variable "kubedns_version" { default = "1.14.1"}

variable "weave_version" { default = "1.9.3"}

variable "weavenet_cidr" { default = "10.5.0.0/16" }

variable "weave_password" {}

variable "kubedns_addon_manifest" { default = "/etc/kubernetes/addons/kubedns.yaml"}

variable "weave_init_addon_manifest" { default = "/etc/kubernetes/addons/weave_init.yaml"}

variable "weave_join_addon_manifest" { default = "/etc/kubernetes/addons/weave_join.yaml"}

variable "federation_control_plane_manifest" {default = "/etc/kubernetes/manifests/federation/federation_control_plane.yaml"}

variable "secret_kubelet_token" {}

variable "secret_kubeproxy_token" {}

variable "aws_public_zone" { default = "jetb.co."}

variable "db_user" {}

variable "db_password" {}

variable "app_container_port" { default = "8000"}

variable "app_instance_replicas" { default = "4"}

variable "aws_tls_cert_arn" { default = ""}
