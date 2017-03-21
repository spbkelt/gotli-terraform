resource "aws_ebs_volume" "couchbase-pv" {
    availability_zone = "${var.aws_zone}"
    size = 15
    type = "gp2"
    tags {
        Name = "couchbase-pv"
        KubernetesCluster = "${var.aws_region}"
    }
}

data "template_file" "db_userdata" {
  count = "${var.nodes_count}"

  template = "${file("${path.module}/userdata.yaml")}"

  vars {
    kubernetes_version = "${var.kubernetes_version}"
    service_dns_ip = "${var.service_dns_ip}"
    kube_api_url = "${var.kube_api_url}"
    cni_plugin_version = "${var.cni_plugin_version}"
    db_user = "${var.db_user}"
    db_password = "${var.db_password}"
    aws_db_pv_id = "${aws_ebs_volume.couchbase-pv.id}"
  }
}

resource "aws_instance" "db" {
  count = "${var.is_kube_api_healthy == "true" ? var.nodes_count : 0}"
  ami = "${var.aws_ami}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "kubernetes"
  user_data = "${data.template_file.db_userdata.rendered}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id = "${var.aws_subnet_private_id}"

  tags {
    Name = "db_${count.index}"
    KubernetesCluster = "${var.aws_region}"
  }
}

resource "aws_volume_attachment" "couchbase" {
  device_name = "/dev/xvdf"
  volume_id   = "${aws_ebs_volume.couchbase-pv.id}"
  instance_id = "${aws_instance.db.id}"
}

resource "null_resource" "init" {

  triggers {
    db_instance_ids = "${join(",", aws_instance.db.*.id)}"
  }

  count = "${var.nodes_count}"

  connection {
        user = "core"
        host = "${element(aws_instance.db.*.private_ip, count.index)}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  provisioner "remote-exec" {
      inline = [
        "sudo mkdir -p /srv/kubernetes/bin",
        "sudo mkdir -p /srv/kubernetes/bin",
        "sudo mkdir -p /etc/kubernetes/manifests",
        "sudo /usr/bin/chmod +w -R /etc/ssl/certs",
        "sudo chown -R core:core /etc/kubernetes",
        "sudo chown -R core:core /srv/kubernetes/bin"
      ]
  }
}

resource "null_resource" "ca_tls" {

  triggers {
    db_instance_ids = "${join(",", aws_instance.db.*.id)}"
  }

  count = "${var.nodes_count}"

  connection {
        user = "core"
        host = "${aws_instance.db.private_ip}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  provisioner "file" {
      source = "${path.root}/pki/ca.pem"
      destination = "/tmp/ca.pem"
  }

  provisioner "remote-exec" {
      inline = [
        "sudo cp /tmp/ca.pem /etc/ssl/certs/ca.pem",
        "sudo /usr/sbin/update-ca-certificates"
      ]
    }

  depends_on = ["null_resource.init"]

}

resource "null_resource" "kubeconfig"{

  triggers {
    worker_instance_ids = "${join(",", aws_instance.db.*.id)}"
  }

  count = "${var.nodes_count}"

  connection {
        user = "core"
        host = "${aws_instance.db.private_ip}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  provisioner "local-exec" {
    command = "export KUBECONFIG=${path.root}/secrets/kubeconfig && ${path.root}/secrets/generate_kubeconfig.sh -u 'kubelet' -a '${var.kube_api_url}' -k '${path.root}/secrets/kubeconfig' -t '${var.secret_kubelet_token}' -r '${var.aws_region}' -c '/etc/ssl/certs/ca.pem'"
  }

  provisioner "local-exec" {
    command = "export KUBECONFIG=${path.root}/secrets/kubeconfig && ${path.root}/secrets/generate_kubeconfig.sh -u 'kube-proxy' -a '${var.kube_api_url}' -k '${path.root}/secrets/kubeconfig' -t '${var.secret_kubeproxy_token}' -r '${var.aws_region}' -c '/etc/ssl/certs/ca.pem'"
  }

  provisioner "file" {
      source = "${path.root}/secrets/kubeconfig"
      destination = "/tmp/kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /home/core/.kube",
      "sudo mkdir -p /root/.kube",
      "sudo cp /tmp/kubeconfig /etc/kubernetes/kubeconfig",
      "sudo /usr/bin/cp /etc/kubernetes/kubeconfig /home/core/.kube/config",
      "sudo /usr/bin/cp /etc/kubernetes/kubeconfig /root/.kube/config"
    ]
  }

 depends_on = ["null_resource.init", "null_resource.ca_tls"]
}
