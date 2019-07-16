output "vnet_id" {
  description = "ID of the created virtual network"
  value       = "${azurerm_virtual_network.network.id}"
}

output "subnet_id" {
  description = "ID of the created main subnet"
  value       = "${azurerm_subnet.network.id}"
}

output "main_network_security_group_name" {
  description = "name of the security group that contains rules for the created main subnet"
  value       = "${azurerm_network_security_group.network.name}"
}

output "bastion_public_ip" {
  description = "list of bastions' IP addressess"
  value       = "${flatten(azurerm_public_ip.bastion.*.ip_address)}"
}

locals {
  inventory = <<EOF
[bastion]
${join("\n", formatlist("%s ansible_host=%s", azurerm_virtual_machine.bastion.*.name, azurerm_public_ip.bastion.*.ip_address))}

[bastion:vars]
ansible_user=ubuntu
${var.ssh_private_key != "" ? "ansible_ssh_private_key_file=${var.ssh_private_key}" : ""}
EOF
}

output "inventory" {
  value = "${local.inventory}"
}
