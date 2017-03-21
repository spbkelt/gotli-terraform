# Create a new load balancer
resource "aws_elb" "elb" {
  internal = "${var.is_internal}"
  subnets = ["${var.subnets}"]
  security_groups = ["${var.security_groups}"]

  listener {
    instance_port = "${var.instance_port}"
    instance_protocol = "${var.instance_protocol}"
    lb_port = "${var.lb_port}"
    lb_protocol = "${var.lb_protocol}"

  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    target = "${var.health_check_target}"
    interval = 30
  }

  instances = ["${var.aws_instances}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 300

  tags {
    Name = "${var.elb_name}"
    KubernetesCluster = "${var.aws_region}"
  }
}

resource "null_resource" "is_healthy" {
  triggers {
    instance_ids = "${join(",", var.aws_instances)}"
  }

  count = 1

  connection {
        user = "core"
        host = "${element(var.aws_instance_private_ips, count.index)}"
        private_key = "${file(var.ssh_private_key_path)}"
        bastion_host = "${var.bastion_host}"
        agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "/usr/bin/curl ${var.schema}://${aws_elb.elb.dns_name}/${var.health_uri_suffix} -s -o /dev/null -w '%{http_code}' -H 'Authorization: Bearer ${var.auth_token}'"
    ]
  }

}
