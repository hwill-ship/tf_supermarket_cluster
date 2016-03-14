module "supermarket-server" {
  source = "./supermarket-server"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"
}
