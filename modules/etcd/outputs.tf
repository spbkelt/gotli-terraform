output "aws_instance_ids" {
  value = ["${aws_instance.etcd.*.id}"]
}

output "aws_instance_private_ips" {
  value = ["${aws_instance.etcd.*.private_ip}"]
}
