output "aws_instance_ids" {
  value = ["${aws_instance.k8s_worker.*.id}"]
}

output "aws_instance_private_ips" {
  value = ["${aws_instance.k8s_worker.*.private_ip}"]
}

output "aws_zones" {
  value = ["${aws_instance.k8s_worker.*.availability_zone}"]
}
