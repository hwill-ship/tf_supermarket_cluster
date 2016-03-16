resource "template_file" "knife_rb" {
  template = "${file("${path.module}/templates/knife_rb.tpl")}"
  vars {
    chef-server-user = "${var.chef-server-user}"
    chef-server-fqdn = "${var.chef-server-fqdn}"
    organization = "${var.chef-server-organization}"
  }
  # Make .chef/knife.rb file
  provisioner "local-exec" {
    command = "mkdir -p .chef && echo '${template_file.knife_rb.rendered}' > .chef/knife.rb"
  }

  # Download chef validation pem
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.private_ssh_key_path} ubuntu@${chef-server-fqdn}:${var.chef-server-user}.pem .chef/${var.chef-server-user}.pem"
  }

  # Fetch Chef Server Certificate
  provisioner "local-exec" {
    command = "knife ssl fetch"
  }
}
