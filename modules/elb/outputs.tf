output "dns_name" {
  value = "${aws_elb.elb.dns_name}"
}

output "is_healthy" {
  value = "true"
  depends_on = ["module.elb.null_resource.is_healthy"]
}
