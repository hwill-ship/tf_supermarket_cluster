resource "template_file" "knife_rb" {
  template = "${file("${path.module}/templates/knife_rb.tpl")}"
  vars {
    chef-server-user = "${var.chef-server-user}"
    chef-server-fqdn = "${var.chef-server-fqdn}"
    organization = "${var.chef-server-organization}"
    supermarket-server-fqdn = "${var.supermarket-server-fqdn}"
  }
  # Make .chef/knife.rb file
  provisioner "local-exec" {
    command = "mkdir -p .chef && echo '${template_file.knife_rb.rendered}' > .chef/knife.rb"
  }

  # Download chef validation pem
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.private_ssh_key_path} ubuntu@${var.chef-server-fqdn}:${var.chef-server-user}.pem .chef"
  }

  # Fetch Chef Server Certificate
  provisioner "local-exec" {
    # changing to the parent directory so the trusted cert goes into ../.chef/trusted_certs
    command = "knife ssl fetch"
  }

  # Upload cookbooks to the Chef Server
  provisioner "local-exec" {
    command = "knife cookbook upload --all --cookbook-path chef-server/cookbooks"
  }

  # Install knife-supermarket
  provisioner "local-exec" {
    command = "sudo chef gem install knife-supermarket"
  }
}
