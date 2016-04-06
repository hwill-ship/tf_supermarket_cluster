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

module "supermarket" {
  source = "./supermarket"
  aws_iam_username = "${var.aws_iam_username}"

  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"

  # Must be assigned to the default security group to be able to connect to other instances (i.e. the RDS DB) on the same VPC
  security_groups = "${module.security-groups.allow-ssh-name},${module.security-groups.allow-443-name},default"

  key_name = "${var.key_name}"

  db_allocated_storage = "${var.db_allocated_storage}"
  db_engine = "${var.db_engine}"
  db_engine_version = "${var.db_engine_version}"
  db_instance_class = "${var.db_instance_class}"
  db_identifier = "${var.db_identifier}"
  db_name = "${var.db_name}"
  db_username = "${var.db_username}"
  db_password = "${var.db_password}"  

  bucket_name = "${var.bucket_name}"
  bucket_acl = "${var.bucket_acl}"

  cache_cluster_name = "${var.cache_cluster_name}"
  cache_cluster_engine = "${var.cache_cluster_engine}"
  cache_cluster_node_type = "${var.cache_cluster_node_type}"
  cache_cluster_port = "${var.cache_cluster_port}"
  cache_cluster_num_nodes = "${var.cache_cluster_num_nodes}"
  cache_parameter_group_name = "${var.cache_parameter_group_name}"
}

module "fieri" {
  source = "./fieri"

  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"

  # Must be assigned to the default security group to be able to connect to other instances (i.e. the RDS DB) on the same VPC
  security_groups = "${module.security-groups.allow-ssh-name},${module.security-groups.allow-443-name},default"

  key_name = "${var.key_name}"
}

module "chef-server" {
  source = "./chef-server" 
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
  instance_type = "${var.instance_type}"
  ami = "${var.ami}"

  # Must be assigned to the default security group to be able to connect to other instances (i.e. the RDS DB) on the same VPC
  security_groups = "${module.security-groups.allow-ssh-name},${module.security-groups.allow-443-name},default"

  key_name = "${var.key_name}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
  chef-server-user = "${var.chef-server-user}"
  chef-server-user-full-name = "${var.chef-server-user-full-name}"
  chef-server-user-email = "${var.chef-server-user-email}"
  chef-server-user-password = "${var.chef-server-user-password}"
  chef-server-org-name = "${var.chef-server-org-name}"
  chef-server-org-full-name = "${var.chef-server-org-full-name}"
  supermarket-redirect-uri = "https://${module.supermarket.public_ip}/auth/chef_oauth2/callback"
}

module "workstation" {
  source = "./workstation"
  chef-server-user = "${var.chef-server-user}"
  chef-server-fqdn = "${module.chef-server.public_ip}"
  chef-server-organization = "${var.chef-server-org-name}"
  private_ssh_key_path = "${var.private_ssh_key_path}"
  supermarket-server-fqdn = "${module.supermarket.public_ip}"
}

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

/*
==============================================================================
This section sets up the Supermarket databag and configures the Supermarket node
==============================================================================
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
    command = "grep -Po '\"secret\".*?[^\\\\]\",' supermarket.json > secret.txt"
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
  "fqdn": "${module.supermarket.public_ip}",
  "chef_server_url": "https://${module.chef-server.public_ip}",
  ${file("uid.txt")}
  ${file("secret.txt")}
  "internal_database_enable": false,
  "database": {
    "host": "${replace(module.supermarket.database_host, "/:\d\d\d\d/","")}",
    "name": "${var.db_name}",
    "password": "${var.db_password}",
    "port": "${module.supermarket.database_port}",
    "username": "${var.db_username}"
  },
  "redis": {
    "enable": false
  },
  "redis_url": "redis://${module.supermarket.elasticache_url}" ,
  "s3_bucket": "${var.bucket_name}",
  "s3_access_key_id": "${var.access_key}",
  "s3_secret_access_key": "${var.secret_key}",
  "fieri_url": "http://${module.fieri.public_dns}/jobs",
  "fieri_key": "${var.fieri_key}",
  "features": "tools,fieri,github,announcement"
}
FILE
EOF
  }
}

resource "null_resource" "supermarket-databag-upload" {
  depends_on = ["null_resource.supermarket-databag-setup"]
  # Create the apps data bag on the Chef server
  provisioner "local-exec" {
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
    command = "knife bootstrap ${module.supermarket.public_ip} -i ${var.private_ssh_key_path} -N supermarket-node -x ubuntu --sudo"
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
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.supermarket.public_ip} 'sudo chef-client'"
  }
}

# Putting this at the very end to allow time for Supermarket node config to complete
resource "null_resource" "fetch-supermarket-certificate" {
  depends_on = ["null_resource.configure-supermarket-node-run-list"]
  # Fetch Supermarket Certificate
  provisioner "local-exec" {
    command = "sleep 360 && knife ssl fetch https://${module.supermarket.public_ip}"
  }
}

/*
==============================================================================
This section sets up the Fieri databag and configures the Fieri node
==============================================================================
*/

resource "null_resource" "fieri-databag-setup" {
  # Running into order of operations issues, don't do this until after the supermarket data bag has been uploaded
  depends_on = ["null_resource.supermarket-databag-upload"]
  # Make json file for fieri data bag item
  provisioner "local-exec" {
    command = <<EOF
    cat <<FILE > databags/apps/fieri.json
{
  "id": "fieri",
  "auth_token": "${var.fieri_key}",
  "results_endpoint": "https://${module.supermarket.public_ip}/api/v1/cookbook-verisons/evaluation"
}
FILE
EOF
  }

  # Upload json file to create data bag
  provisioner "local-exec" {
    command = "knife data bag from file apps databags/apps/fieri.json"
  }  
}

resource "null_resource" "fieri-node-setup" {
  # Running into timing issues with bootstrapping the fieri node, so adding in a sleep of 720 to give it more time to become available
  depends_on = ["null_resource.fieri-databag-setup"]
  provisioner "local-exec" {
    command = "sleep 720 && knife bootstrap ${module.fieri.public_ip} -i ${var.private_ssh_key_path} -N fieri-node -x ubuntu --sudo"
  }
}

resource "null_resource" "configure-fieri-node-run-list" {
  depends_on = ["null_resource.fieri-node-setup"]
  provisioner "local-exec" {
    command = "knife node run_list add fieri-node 'recipe[fieri::default]'"
  }
}

resource "null_resource" "fieri-node-client" {
  depends_on = ["null_resource.configure-fieri-node-run-list"]
  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'sudo chef-client'"
  }
}

resource "null_resource" "supermarket-fieri-certificate-setup" {
  depends_on = ["null_resource.fieri-node-client"]
  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.supermarket.public_ip} 'sudo chown ubuntu /var/opt/supermarket'"
  }

  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.supermarket.public_ip} 'sudo chown ubuntu /var/opt/supermarket/ssl'"
  }

  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.supermarket.public_ip} 'sudo chown ubuntu /var/opt/supermarket/ssl/ca'"
  }

  provisioner "local-exec" {
    command = "scp -i ${var.private_ssh_key_path} ubuntu@${module.supermarket.public_ip}:/var/opt/supermarket/ssl/ca/${module.supermarket.public_ip}.crt ."
  }

  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'sudo chown ubuntu /usr/share/ca-certificates'"
  }

  provisioner "local-exec" {
    command = "scp -i ${var.private_ssh_key_path} ./${module.supermarket.public_ip}.crt ubuntu@${module.fieri.public_ip}:/usr/share/ca-certificates"
  }

  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'sudo chown ubuntu /etc/ca-certificates.conf'"
  }

  provisioner "local-exec" {
    # This adds the supermarket self signed certificate to the top of the list of certificates in /etc/ca-certificates.conf on the Fieri server
#    command = "scp -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'sed -i 's/mozilla\/A-Trust-nQual-03.crt/${module.supermarket.public_ip}.crt\nmozilla\/A-Trust-nQual-03.crt/'"
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'echo ${module.supermarket.public_ip}.crt >> /etc/ca-certificates.conf'"
  }

  provisioner "local-exec" {
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${module.fieri.public_ip} 'sudo update-ca-certificates'"
  }
}
