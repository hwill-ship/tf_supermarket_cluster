resource "null_resource" "supermarket-node-setup" {

  # Forces 360 second wait to allow other modules to finish before this one
  # Terraform does not currently let you use depends_on with a module
  provisioner "local-exec" {
    command = "sleep 360 && knife bootstrap ${var.supermarket-server-public-ip} -i ${var.private_ssh_key_path} -N supermarket-node -x ubuntu --sudo"
  }
}
