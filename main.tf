# Specify the provider and access details
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"

  region = "${var.aws_region}"
}

resource "aws_kms_key" "kms_key" {
  deletion_window_in_days = 7
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${file(var.ssh_public_key_path)}"
}

module "iam" {
  source = "./modules/iam"
}

module "vpc" {
  source = "./modules/vpc"
  ssh_key_name = "${var.ssh_key_name}"
  aws_region = "${var.aws_region}"
}

module "bastion" {
  source = "./modules/bastion"
  ssh_key_name = "${var.ssh_key_name}"
  aws_ami = "${lookup(var.aws_amis, var.aws_region)}"
  vpc_security_group_ids = ["${module.vpc.aws_security_group_ssh_public_id}"]
  aws_subnet_public_id = "${module.vpc.aws_subnet_public_id}"
  aws_region = "${var.aws_region}"
}

module "etcd" {
  source = "./modules/etcd"
  bastion_ip = "${module.bastion.public_ip}"
  nodes_count = "${var.etcd_nodes_count}"
  discovery_url = "${var.discovery_url}"
  ssh_key_name = "${var.ssh_key_name}"
  aws_ami = "${lookup(var.aws_amis, var.aws_region)}"
  vpc_security_group_ids = ["${module.vpc.aws_security_group_ssh_private_id}", "${module.vpc.aws_security_group_etcd_id}"]
  aws_subnet_private_id = "${module.vpc.aws_subnet_private_id}"
  aws_region = "${var.aws_region}"
}

module "etcd_elb" {
  source = "./modules/elb"
  is_internal = true
  elb_name = "etcd-api-elb"
  subnets = ["${module.vpc.aws_subnet_private_id}"]
  security_groups = ["${module.vpc.aws_security_group_kubernetes_id}"]
  aws_instances = "${module.etcd.aws_instance_ids}"
  instance_port = "2379"
  lb_port = "80"
  instance_protocol = "HTTP"
  lb_protocol = "HTTP"
  health_check_target = "HTTP:2379/health"
  aws_region = "${var.aws_region}"
  health_uri_suffix = "health"
  schema = "http"
  aws_instance_private_ips = "${module.etcd.aws_instance_private_ips}"
  auth_token = ""
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
}

module "k8s_master" {
  source = "./modules/k8s_master"
  is_etcd_healthy = "${module.etcd_elb.is_healthy}"
  nodes_count = "${var.master_nodes_count}"
  service_dns_ip = "${var.service_dns_ip}"
  cluster_service_cidr = "${var.cluster_service_cidr}"
  kubernetes_version = "${var.kubernetes_version}"
  ssh_key_name = "${var.ssh_key_name}"
  aws_region = "${var.aws_region}"
  service_api_ip = "${var.service_api_ip}"
  aws_ami = "${lookup(var.aws_amis, var.aws_region)}"
  vpc_security_group_ids = ["${module.vpc.aws_security_group_ssh_private_id}", "${module.vpc.aws_security_group_kubernetes_id}"]
  aws_subnet_private_id = "${module.vpc.aws_subnet_private_id}"
  etcd_elb_url = "http://${module.etcd_elb.dns_name}"
  cni_plugin_version = "${var.cni_plugin_version}"
  aws_kms_key_arn = "${aws_kms_key.kms_key.arn}"
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
  kubedns_addon_manifest = "${var.kubedns_addon_manifest}"
  weave_init_addon_manifest = "${var.weave_init_addon_manifest}"
  weave_version = "${var.weave_version}"
  weavenet_cidr = "${var.weavenet_cidr}"
  weave_password = "${var.weave_password}"
  kubedns_version = "${var.kubedns_version}"
}

module "kube_api_elb" {
  source = "./modules/elb"
  is_internal = true
  elb_name = "kubernetes-api-elb"
  health_check_target = "HTTP:8080/healthz"
  subnets = ["${module.vpc.aws_subnet_private_id}"]
  security_groups = ["${module.vpc.aws_security_group_kubernetes_id}"]
  aws_instances = "${module.k8s_master.aws_instance_ids}"
  instance_port = "443"
  instance_protocol = "TCP"
  lb_port = "443"
  lb_protocol = "TCP"
  aws_region = "${var.aws_region}"
  health_uri_suffix = "healthz"
  schema ="https"
  auth_token = "${var.secret_kubelet_token}"
  aws_instance_private_ips = "${module.k8s_master.aws_instance_private_ips}"
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
}

module "k8s_worker" {
  source = "./modules/k8s_worker"
  is_kube_api_healthy = "${module.kube_api_elb.is_healthy}"
  nodes_count = "${var.worker_nodes_count}"
  service_dns_ip = "${var.service_dns_ip}"
  cluster_service_cidr = "${var.cluster_service_cidr}"
  kubernetes_version = "${var.kubernetes_version}"
  ssh_key_name = "${var.ssh_key_name}"
  aws_region = "${var.aws_region}"
  service_api_ip = "${var.service_api_ip}"
  aws_ami = "${lookup(var.aws_amis, var.aws_region)}"
  vpc_security_group_ids = ["${module.vpc.aws_security_group_ssh_private_id}", "${module.vpc.aws_security_group_kubernetes_id}"]
  aws_subnet_private_id = "${module.vpc.aws_subnet_private_id}"
  kube_api_url = "https://${module.kube_api_elb.dns_name}"
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
  secret_kubeproxy_token = "${var.secret_kubeproxy_token}"
  secret_kubelet_token = "${var.secret_kubelet_token}"
  cni_plugin_version = "${var.cni_plugin_version}"
}

module "federation" {
  source = "./modules/federation"
  is_kube_api_healthy = "${module.kube_api_elb.is_healthy}"
  federation_control_plane_manifest = "${var.federation_control_plane_manifest}"
  aws_public_zone = "${var.aws_public_zone}"
  kubernetes_version = "${var.kubernetes_version}"
  k8s_master_private_ips = "${module.k8s_master.aws_instance_private_ips}"
  k8s_master_instance_ids = "${module.k8s_master.aws_instance_ids}"
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
  k8s_master_ip = "${element(module.k8s_master.aws_instance_private_ips, 0)}"
}

resource "aws_route53_zone" "main" {
   name = "${var.aws_public_zone}"
}

module "db" {
  source = "./modules/db"
  is_kube_api_healthy = "${module.kube_api_elb.is_healthy}"
  nodes_count = "${var.db_nodes_count}"
  ssh_key_name = "${var.ssh_key_name}"
  kubernetes_version = "${var.kubernetes_version}"
  service_dns_ip = "${var.service_dns_ip}"
  instance_type = "t2.medium"
  aws_ami = "${lookup(var.aws_amis, var.aws_region)}"
  aws_region = "${var.aws_region}"
  vpc_security_group_ids = ["${module.vpc.aws_security_group_ssh_private_id}", "${module.vpc.aws_security_group_kubernetes_id}"]
  aws_subnet_private_id = "${module.vpc.aws_subnet_private_id}"
  ssh_private_key_path = "${var.ssh_private_key_path}"
  bastion_host = "${module.bastion.public_ip}"
  secret_kubeproxy_token = "${var.secret_kubeproxy_token}"
  secret_kubelet_token = "${var.secret_kubelet_token}"
  cni_plugin_version = "${var.cni_plugin_version}"
  kube_api_url = "https://${module.kube_api_elb.dns_name}"
  db_user = "${var.db_user}"
  db_password = "${var.db_password}"
  aws_zone = "${element(module.k8s_worker.aws_zones, 0 )}"

}

module "application" {
  source = "./modules/application"
  app_instance_replicas = "${var.app_instance_replicas}"
  aws_regions_ecr_image_map = "${var.aws_regions_ecr_image_map}"
  app_container_port = "${var.app_container_port}"
  aws_region = "${var.aws_region}"
  aws_tls_cert_arn = "${var.aws_tls_cert_arn}"

}
