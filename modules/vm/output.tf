locals {
  inventory = <<EOF
[${var.vm_name}]
${join("\n", formatlist("%s ansible_host=%s", azurerm_virtual_machine.vm.*.name, coalescelist(azurerm_public_ip.vm.*.ip_address, azurerm_network_interface.vm.*.private_ip_address)))}

[${var.vm_name}:vars]
ansible_user=ubuntu
${var.bastion_ip != "" ? "${local.ansible_ssh_common_args}" : ""}
${var.ssh_private_key != "" ? "ansible_ssh_private_key_file=${var.ssh_private_key}" : ""}
EOF
}

locals {
  ansible_ssh_common_args = <<EOF
ansible_ssh_common_args='-o ProxyCommand="ssh -o StrictHostKeyChecking=no -W %h:%p -q ${var.ssh_private_key != "" ? "-i ${var.ssh_private_key}" : ""} ubuntu@${var.bastion_ip}"'
EOF
}

output "inventory" {
  value = "${local.inventory}"
}
