output "aws_security_group_ssh_private_id" {
  value = "${aws_security_group.ssh_private.id}"
}

output "aws_security_group_ssh_public_id" {
  value = "${aws_security_group.ssh_public.id}"
}

output "aws_security_group_etcd_id" {
  value = "${aws_security_group.etcd.id}"
}

output "aws_security_group_kubernetes_id" {
  value = "${aws_security_group.kubernetes.id}"
}

output "aws_subnet_private_id" {
  value = "${aws_subnet.kube_private.id}"
}

output "aws_subnet_public_id" {
  value = "${aws_subnet.kube_public.id}"
}

output "vpc_id" {
  value = "${aws_vpc.kubernetes.id}"
}
