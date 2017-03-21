data "template_file" "userdata_master" {
  template = "${file("${path.module}/userdata.yaml")}"

  vars {
    kubernetes_version = "${var.kubernetes_version}"
    cluster_service_cidr = "${var.cluster_service_cidr}"
    service_dns_ip = "${var.service_dns_ip}"
    etcd_elb_url = "${var.etcd_elb_url}"
    nodes_count = "${var.nodes_count}"
    cni_plugin_version = "${var.cni_plugin_version}"
    aws_region = "${var.aws_region}"
    service_api_ip = "${var.service_api_ip}"
    weave_init_addon_manifest = "${var.weave_init_addon_manifest}"
    kubedns_addon_manifest = "${var.kubedns_addon_manifest}"
    cni_plugin_version = "${var.cni_plugin_version}"
    weave_version = "${var.weave_version}"
    weavenet_cidr = "${var.weavenet_cidr}"
    weave_password = "${var.weave_password}"
    kubedns_version = "${var.kubedns_version}"
  }
}

data "template_file" "openssl_config" {

  count = "${var.nodes_count}"

  template = "${file("${path.root}/pki/openssl.cnf.tpl")}"

  vars {
    service_api_ip = "${var.service_api_ip}"
    aws_region = "${var.aws_region}"
    k8s_master_ip = "${element(aws_instance.k8s_master.*.private_ip, count.index)}"

  }
}

data "template_file" "kube_dns" {
  template = "${file("${path.root}/k8s_addons/kube_dns.yaml")}"

  vars {
    service_dns_ip = "${var.service_dns_ip}"
    kubedns_version = "${var.kubedns_version}"
  }
}

data "template_file" "weave_init" {
  template = "${file("${path.root}/k8s_addons/weave_init.yaml")}"

  vars {
    weave_version = "${var.weave_version}"
    weavenet_cidr = "${var.weavenet_cidr}"
    weave_password = "${var.weave_password}"
  }
}

resource "aws_instance" "k8s_master" {
  count = "${var.is_etcd_healthy == "true" ? var.nodes_count : 0}"

  ami = "${var.aws_ami}"
  instance_type = "t2.micro"
  iam_instance_profile = "kubernetes"
  user_data = "${data.template_file.userdata_master.rendered}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id = "${var.aws_subnet_private_id}"

  tags {
    Name = "k8s_master_${count.index}"
    KubernetesCluster = "${var.aws_region}"
  }

}

resource "null_resource" "init" {

  triggers {
    master_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
  }

  count = "${var.nodes_count}"

  connection {
        user = "core"
        host = "${element(aws_instance.k8s_master.*.private_ip, count.index)}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  provisioner "remote-exec" {
      inline = [
        "sudo mkdir -p /srv/kubernetes/bin",
        "sudo mkdir -p /etc/kubernetes/addons",
        "sudo mkdir -p /srv/kubernetes/bin",
        "sudo mkdir -p /etc/kubernetes/ssl",
        "sudo mkdir -p /etc/kubernetes/manifests",
        "sudo mkdir -p /home/core/.kube",
        "sudo /usr/bin/chmod +w -R /etc/ssl/certs",
        "sudo chown -R core:core /etc/kubernetes",
        "sudo chown -R core:core /srv/kubernetes/bin"
      ]
  }

}

  resource "null_resource" "ca_tls" {

    triggers {
      master_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
    }

    count = "${var.nodes_count}"

    connection {
          user = "core"
          host = "${element(aws_instance.k8s_master.*.private_ip, count.index)}"
          private_key = "${file(var.ssh_private_key_path)}"
          bastion_host = "${var.bastion_host}"
          agent = false
    }

    provisioner "local-exec" {
        command = "openssl genrsa -out ${path.root}/pki/ca-key.pem 2048"
    }

    provisioner "local-exec" {
        command = "openssl req -x509 -new -nodes -key ${path.root}/pki/ca-key.pem -days 365 -out ${path.root}/pki/ca.pem -subj /CN=kube-ca"
    }

    provisioner "file" {
        source = "${path.root}/pki/ca.pem"
        destination = "/tmp/ca.pem"
    }

    provisioner "file" {
        source = "${path.root}/pki/ca-key.pem"
        destination = "/tmp/ca-key.pem"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo cp /tmp/ca.pem /etc/ssl/certs/ca.pem",
          "sudo cp /tmp/ca-key.pem /etc/ssl/certs/ca-key.pem",
          "sudo /usr/sbin/update-ca-certificates"
        ]
      }

    depends_on = ["null_resource.init"]

  }

  resource "null_resource" "api_tls" {

    triggers {
      master_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
    }

    count = "${var.nodes_count}"

    connection {
          user = "core"
          host = "${element(aws_instance.k8s_master.*.private_ip, count.index)}"
          private_key = "${file(var.ssh_private_key_path)}"
          bastion_host = "${var.bastion_host}"
          agent = false
    }

    provisioner "local-exec" {
        command = "mkdir -p ${path.root}/pki/k8s_master/${count.index}"

    }

    provisioner "local-exec" {
        command = "echo \"${element(data.template_file.openssl_config.*.rendered, count.index)}\" > ${path.root}/pki/k8s_master/${count.index}/openssl.cnf"

    }

    provisioner "local-exec" {
        command = "openssl genrsa -out  ${path.root}/pki/k8s_master/${count.index}/apiserver-key.pem 2048"
    }

    provisioner "local-exec" {
        command = "openssl req -new -key ${path.root}/pki/k8s_master/${count.index}/apiserver-key.pem -out  ${path.root}/pki/k8s_master/${count.index}/apiserver.csr -subj '/CN=kube-apiserver' -config  ${path.root}/pki/k8s_master/${count.index}/openssl.cnf"

    }

    provisioner "local-exec" {
        command = "openssl x509 -req -in ${path.root}/pki/k8s_master/${count.index}/apiserver.csr -CA ${path.root}/pki/ca.pem -CAkey ${path.root}/pki/ca-key.pem -CAcreateserial -out ${path.root}/pki/k8s_master/${count.index}/apiserver.pem -days 365 -extensions v3_req -extfile ${path.root}/pki/k8s_master/${count.index}/openssl.cnf"

    }

    provisioner "file" {
        source = "${path.root}/pki/k8s_master/${count.index}/apiserver.pem"
        destination = "/tmp/apiserver.pem"
    }

    provisioner "file" {
        source = "${path.root}/pki/k8s_master/${count.index}/apiserver-key.pem"
        destination = "/tmp/apiserver-key.pem"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo cp /tmp/apiserver.pem /etc/kubernetes/ssl/apiserver.pem",
        "sudo cp /tmp/apiserver-key.pem /etc/kubernetes/ssl/apiserver-key.pem"
      ]
    }

    depends_on = ["null_resource.init", "null_resource.ca_tls"]
  }

  resource "null_resource" "secrets" {

    triggers {
      master_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
    }

    count = "${var.nodes_count}"

    connection {
          user = "core"
          host = "${element(aws_instance.k8s_master.*.private_ip, count.index)}"
          private_key = "${file(var.ssh_private_key_path)}"
          bastion_host = "${var.bastion_host}"
          agent = false
    }

    provisioner "file" {
        source = "${path.root}/secrets/known_tokens.csv"
        destination = "/tmp/known_tokens.csv"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo cp /tmp/known_tokens.csv /etc/kubernetes/known_tokens.csv"
      ]
    }

    depends_on = ["null_resource.init"]
  }

  resource "null_resource" "dns_addon" {

    triggers {
      worker_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
    }

    count = "${var.nodes_count}"

    connection {
          user = "core"
          host = "${element(aws_instance.k8s_master.*.private_ip, 0)}"
          private_key = "${file(var.ssh_private_key_path)}"
          bastion_host = "${var.bastion_host}"
          agent = false
    }

    provisioner "file" {
        content = "${data.template_file.kube_dns.rendered}"
        destination = "/tmp/kube_dns.yaml"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo /usr/bin/cp /tmp/kube_dns.yaml  ${var.kubedns_addon_manifest}"
        ]
    }

    depends_on = ["null_resource.init"]

  }

  resource "null_resource" "cni_addon" {

    triggers {
      worker_instance_ids = "${join(",", aws_instance.k8s_master.*.id)}"
    }

    count = "${var.nodes_count}"

    connection {
          user = "core"
          host = "${element(aws_instance.k8s_master.*.private_ip, 0)}"
          private_key = "${file(var.ssh_private_key_path)}"
          bastion_host = "${var.bastion_host}"
          agent = false
    }

    # Copies the string in content into /tmp/file.log
    provisioner "file" {
        content = "${data.template_file.weave_init.rendered}"
        destination = "/tmp/weave_init.yaml"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo /usr/bin/cp /tmp/weave_init.yaml  ${var.weave_init_addon_manifest}"
        ]
    }

    depends_on = ["null_resource.init"]
  }
