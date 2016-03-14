provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "chef-server" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags {
    Name = "chef-server"
  }
  security_groups = ["${split(",", var.security_groups)}"]
  key_name = "${var.key_name}"

  provisioner "file" {
    source = "cookbooks"
    destination = "/tmp" 
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file(\"${var.private_ssh_key_path}\")}"
    }
  }
}
