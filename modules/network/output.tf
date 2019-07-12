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
