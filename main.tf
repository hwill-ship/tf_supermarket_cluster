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
  supermarket-redirect-uri = "https://${module.supermarket-server.public_ip}/auth/chef_oauth2/callback"
}

module "workstation" {
  source = "./workstation"
  chef-server-user = "${var.chef-server-user}"
  chef-server-fqdn = "${module.chef-server.public_ip}"
  chef-server-organization = "${var.chef-server-org-name}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
}

module "databags" {
  source = "./databags"
  chef-server-fqdn = "${module.chef-server.public_ip}"
  chef-server-organization = "${var.chef-server-org-name}"
  chef-server-user = "${var.chef-server-user}"
  chef-private-key-path = ".chef/${var.chef-server-user}.pem"
  supermarket-fqdn = "${module.supermarket-server.public_ip}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
}

module "nodes" {
  source = "./nodes"
  supermarket-server-public-ip = "${module.supermarket-server.public_ip}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
}
