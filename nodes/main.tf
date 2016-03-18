resource "null_resource" "supermarket-node-setup" {

  # Forces 360 second wait to allow other modules to finish before this one
  # Terraform does not currently let you use depends_on with a module
  provisioner "local-exec" {
    command = "sleep 360 && knife bootstrap ${var.supermarket-server-public-ip} -i ${var.private_ssh_key_path} -N supermarket-node -x ubuntu --sudo"
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
    command = "ssh -i ${var.private_ssh_key_path} ubuntu@${var.supermarket-server-public-ip} 'sudo chef-client'"
  }
}
