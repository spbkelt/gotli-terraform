data "template_file" "app_deployment" {
  template = "${file("${path.module}/deployment_service.yaml.tpl")}"

  vars {
    image_uri = "${lookup(var.aws_regions_ecr_image_map, var.aws_region)}"
    instance_replicas = "${var.app_instance_replicas}"
    app_container_port = "${var.app_container_port}"
    aws_tls_cert_arn = "${var.aws_tls_cert_arn}"
  }
}

resource "null_resource" "deployment_service"{

  provisioner "local-exec" {
    command = "echo ${data.template_file.app_deployment.rendered} > ${path.module}/deployment_service.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl use-context federation-cluster && kubectl apply -f ${path.module}/deployment_service.yaml"
  }
}
