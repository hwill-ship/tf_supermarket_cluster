provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "security-groups" {
  source = "./security-groups"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

module "supermarket-server" {
  source = "./supermarket-server"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"
  security_groups = "${module.security-groups.allow-ssh-name},${module.security-groups.allow-443-name}"
  key_name = "${var.key_name}"
}

module "chef-server" {
  source = "./chef-server" 
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"
  security_groups = "${module.security-groups.allow-ssh-name},${module.security-groups.allow-443-name}"
  key_name = "${var.key_name}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
  chef-server-user = "${var.chef-server-user}"
  chef-server-user-full-name = "${var.chef-server-user-full-name}"
  chef-server-user-email = "${var.chef-server-user-email}"
  chef-server-user-password = "${var.chef-server-user-password}"
  chef-server-org-name = "${var.chef-server-org-name}"
  chef-server-org-full-name = "${var.chef-server-org-full-name}"
}
