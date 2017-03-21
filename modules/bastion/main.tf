resource "aws_instance" "bastion" {
  ami = "${var.aws_ami}"
  instance_type = "t2.nano"
  key_name = "${var.ssh_key_name}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id = "${var.aws_subnet_public_id}"
  tags {
    Name = "bastion"
    KubernetesCluster = "${var.aws_region}"
  }
}
