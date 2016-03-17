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

resource "null_resource" "supermarket-oc-id-info" {
   # Changes ownership of /etc/opscode/oc-id-applications/supermarket.json on the Chef Server
  # So it can be pulled down to the local workstation using the ubuntu user
  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${var.chef-server-fqdn} 'sudo chown ubuntu /etc/opscode/oc-id-applications/supermarket.json'"
  }

  # Pulls down supermarket oc-id config from the Chef server 
  provisioner "local-exec" {
    command = "scp -i ${var.private_ssh_key_path} ubuntu@${var.chef-server-fqdn}:/etc/opscode/oc-id-applications/supermarket.json ."
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
  "fqdn": "${var.supermarket-fqdn}",
  "chef_server_url": "https://${var.chef-server-fqdn}"
}
FILE
EOF

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
