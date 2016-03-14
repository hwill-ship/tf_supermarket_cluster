output "allow-ssh-name" {
  value = "${aws_security_group.allow-ssh.name}"
}

output "allow-443-name" {
  value = "${aws_security_group.allow-443.name}"
}
