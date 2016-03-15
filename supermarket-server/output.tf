output "public_ip" {
  value = "${aws_instance.supermarket-server.public_ip}"
}
