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

/*
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
*/


# Configure the Chef provider
# This is commented out because it is current failing with the error "chef_data_bag.apps: Post https://chef-server-fqdn/organizations/data: x509: cannot validate certificate for chef-server-fqdn because it doesn't contain any IP SANs"
/*
provider "chef" {
  server_url = "https://${module.chef-server.public_ip}/organizations/${var.chef-server-org-name}"

 client_name = "${var.chef-server-user}"
 private_key_pem = "${file(".chef/${var.chef-private-key-path}.pem")}"
}

resource "chef_data_bag" "apps" {
    name = "supermarket"
}
*/

resource "null_resource" "supermarket-oc-id-info" {
   # Changes ownership of /etc/opscode/oc-id-applications/supermarket.json on the Chef Server
  # So it can be pulled down to the local workstation using the ubuntu user
  # Force sleep for 60 seconds so other modules have a chance to finish
  provisioner "local-exec" {
    command = "sleep 60 && ssh -i ${var.private_ssh_key_path} ubuntu@${module.chef-server.public_ip} 'sudo chown ubuntu /etc/opscode/oc-id-applications/supermarket.json'"
  }

  # Pulls down supermarket oc-id config from the Chef server 
  provisioner "local-exec" {
    command = "scp -i ${var.private_ssh_key_path} ubuntu@${module.chef-server.public_ip}:/etc/opscode/oc-id-applications/supermarket.json ."
  } 

  # Extract uid from supermarket oc-id config 
  provisioner "local-exec" {
    command = "grep -Po '\"uid\".*?[^\\\\]\",' supermarket.json > uid.txt"
  }

  # Extract secret from supermarket oc-id config
  provisioner "local-exec" {
    command = "grep -Po '\"secret\".*?[^\\\\]\"(?=,)' supermarket.json > secret.txt"
  }
}

resource "null_resource" "supermarket-databag-setup" {
  depends_on = ["null_resource.supermarket-oc-id-info"]

  # Make a data bags directory
  provisioner "local-exec" {
    command = "mkdir -p databags/apps"
  }

  # Make json file for supermarket data bag item
  # Using a heredoc, rather than a template
  # Because I could not pass the values of oc-id.txt and secret.txt
  # to the template because they are dynamically created when the terraform
  # config runs
  provisioner "local-exec" {
    command = <<EOF
    cat <<FILE > databags/apps/supermarket.json
{
  "id": "supermarket",
  "fqdn": "${module.supermarket-server.public_ip}",
  "chef_server_url": "https://${module.chef-server.public_ip}",
  ${file("uid.txt")}
  ${file("secret.txt")} 
}
FILE
EOF
  }
}

resource "null_resource" "supermarket-databag-upload" {
  depends_on = ["null_resource.supermarket-databag-setup"]
  # Create the apps data bag on the Chef server
  provisioner "local-exec" {
  # Sleep 60 is a hack so that this module will not run until the workstation module is complete
  # Currently terraform will not allow you to use depends_on with a module
  # https://github.com/hashicorp/terraform/issues/1178
    command = "knife data bag create apps"
  }

  # Create supermarket data bag item on the Chef server
  provisioner "local-exec" {
    command = "knife data bag from file apps databags/apps/supermarket.json"
  }  
}

resource "null_resource" "supermarket-node-setup" {
  depends_on = ["null_resource.supermarket-databag-upload"]
  provisioner "local-exec" {
    command = "knife bootstrap ${module.supermarket-server.public_ip} -i ${var.private_ssh_key_path} -N supermarket-node -x ubuntu --sudo"
  }
}

resource "null_resource" "configure-supermarket-node-run-list" {
  depends_on = ["null_resource.supermarket-node-setup"]
  provisioner "local-exec" {
    command = "knife node run_list add supermarket-node 'recipe[supermarket-wrapper::default]'"
  }
}

resource "null_resource" "supermarket-node-client" {
  depends_on = ["null_resource.configure-supermarket-node-run-list"]
  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.supermarket-server.public_ip} 'sudo chef-client'"
  }
}
