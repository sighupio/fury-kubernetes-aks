data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

variable "name" {
  description = "name of the project"
  type        = "string"
}

variable "env" {
  description = "name of the environment"
  type        = "string"
}

variable "resource_group_name" {
  description = "name of the azurerm_resource_group to use"
  type        = "string"
}

variable "vnet_cidr" {
  description = "virtual network CIDR (address_space)"
  type        = "string"
}

variable "main_subnet_endpoints" {
  description = "list of service endpoints to associate with the main subnet"
  type        = "list"
  default     = []
}

variable "bastion_count" {
  description = "number of bastion hosts"
  type        = "string"
  default     = 1
}

variable "bastion_node_image" {
  description = "bastion host VM image - must contain mappings for string-keys (publisher, offer, sku, version)"
  type        = "map"
}

variable "bastion_node_size" {
  description = "bastion host VM type (vm_size)"
  type        = "string"
  default     = "Standard_B1s"
}

variable "bastion_enable_ssh" {
  description = "set to true (boolean) to enable creation of security rule for SSH"
  type        = "string"
  default     = true
}

variable "bastion_enable_openvpn" {
  description = "set to true (boolean) to enable creation of security rule for OpenVPN"
  type        = "string"
  default     = true
}

variable "ssh_public_key" {
  description = "local path to the authorized SSH public key to connect to the bastion"
  type        = "string"
}

# ASSUMPTIONS
# main_subnet_cidr = "${cidrsubnet(var.vnet_cidr, 1, 0)}"
# bastion_subnet_cidr = "${cidrsubnet(var.vnet_cidr, 1, 1)}"

