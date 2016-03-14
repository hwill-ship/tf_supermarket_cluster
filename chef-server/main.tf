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
}
