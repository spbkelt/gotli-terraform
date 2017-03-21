data "template_file" "federation_control_plane" {
  template = "${file("${path.module}/federation_control_plane.yaml")}"

  vars {
    kubernetes_version = "${var.kubernetes_version}"
    aws_public_zone = "${var.aws_public_zone}"
    k8s_master_ip = "${var.k8s_master_ip}"
  }
}


resource "null_resource" "federation_control_plane" {

  count = "${var.is_kube_api_healthy == "true" ? 1 : 0}"

  triggers {
    master_instance_ids = "${join(",", var.k8s_master_instance_ids)}"
  }

  connection {
        user = "core"
        host = "${var.k8s_master_ip}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  # Copies the string in content into /tmp/file.log
  provisioner "file" {
      content = "${data.template_file.federation_control_plane.rendered}"
      destination = "/tmp/federation_control_plane.yaml"
  }

  provisioner "remote-exec" "secret"{
      inline = [
        "sudo /srv/kubernetes/bin/kubectl  create namespace federation-system",
        "sudo /srv/kubernetes/bin/kubectl  create secret generic federation-apiserver-secrets --from-file=/etc/kubernetes/known_tokens.csv -n federation-system"
      ]
  }

  provisioner "remote-exec" {
      inline = [
        "sudo mkdir -p /etc/kubernetes/manifests/federation",
        "sudo /usr/bin/cp /tmp/federation_control_plane.yaml  ${var.federation_control_plane_manifest}",
        "sudo /srv/kubernetes/bin/kubectl apply -f ${var.federation_control_plane_manifest} -n federation-system",

      ]

  }


}
