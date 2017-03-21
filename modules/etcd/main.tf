data "template_file" "userdata" {
  template = "${file("${path.module}/userdata.yml")}"

  vars {
    discovery_url = "${var.discovery_url}"
  }
}

resource "aws_instance" "etcd" {
  count = "${var.nodes_count}"
  ami = "${var.aws_ami}"
  instance_type = "t2.nano"
  user_data = "${data.template_file.userdata.rendered}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id = "${var.aws_subnet_private_id}"
  tags {
    Name = "etcd2"
    KubernetesCluster = "${var.aws_region}"
  }
}
