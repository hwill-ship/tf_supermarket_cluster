# Configure the Chef provider
# This is commented out because it is current failing with the error "chef_data_bag.apps: Post https://chef-server-fqdn/organizations/data: x509: cannot validate certificate for chef-server-fqdn because it doesn't contain any IP SANs"
/*
provider "chef" {
  server_url = "https://${var.chef-server-fqdn}/organizations/${var.chef-server-organization}"

 client_name = "${var.chef-server-user}"
 private_key_pem = "${file("${var.chef-private-key-path}")}"
}

resource "chef_data_bag" "apps" {
    name = "supermarket"
}
*/

resource "template_file" "supermarket-databag" {
  template = "${file("${path.module}/templates/supermarket_databag.tpl")}"

  vars {
    fqdn = "${var.supermarket-fqdn}"
    chef-server-fqdn = "${var.chef-server-fqdn}"
  }
}

resource "null_resource" "supermarket-databag-setup" {
  # Make a data bags directory
  provisioner "local-exec" {
    command = "mkdir -p databags/apps"
  }

  # Make json file for supermarket data bag item
  provisioner "local-exec" {
    command = "echo '${template_file.supermarket-databag.rendered}' > databags/apps/supermarket.json"
  }

  # Create the apps data bag on the Chef server
  provisioner "local-exec" {
  # Sleep 60 is a hack so that this module will not run until the workstation module is complete
  # Currently terraform will not allow you to use depends_on with a module
  # https://github.com/hashicorp/terraform/issues/1178

    command = "sleep 60 && knife data bag create apps"
  }

  # Create supermarket data bag item on the Chef server
  provisioner "local-exec" {
    command = "knife data bag from file apps databags/apps/supermarket.json"
  }  
}
