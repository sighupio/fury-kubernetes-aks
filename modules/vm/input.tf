data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

data "azurerm_network_security_group" "main" {
  name                = "${var.network_security_group_name}"
  resource_group_name = "${var.resource_group_name}"
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

variable "subnet_id" {
  description = "ID of the subnet into which to create VMs"
  type        = "string"
}

variable "network_security_group_name" {
  description = "name of the network security group associated with the subnet corresponding to subnet_id"
  type        = "string"
}

variable "enable_public_ip" {
  description = "set to true (boolean) to provision and associate public IP addresses with the created VMs"
  type        = "string"
  default     = false
}

variable "security_rules" {
  description = "list of maps representing security rules (name, priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix) to be applied to the created VMs"
  type        = "list"
  default     = []
}

variable "role_assignments" {
  description = "list of maps representing role assignments (scope, role_definition_name) to be applied to the created VMs"
  type        = "list"
  default     = []
}

variable "vm_name" {
  description = "name of the VM group (e.g. build)"
  type        = "string"
}

variable "vm_count" {
  description = "number of VMs to create"
  type        = "string"
  default     = 1
}

variable "vm_image" {
  description = "VM image - must contain mappings for string-keys (publisher, offer, sku, version)"
  type        = "map"
}

variable "vm_size" {
  description = "VM type (e.g. Standard_B1ms)"
  type        = "string"
}

variable "storage_os_disk_size" {
  description = "number indicating the size of the storage disk of the created VMs in gigabytes"
  type        = "string"
  default     = 80
}

variable "vm_disks" {
  description = "list of maps representing managed disks (storage_account_type, disk_size_gb) that are to be created and attached to the created VMs"
  type        = "list"
  default     = []
}

variable "bastion_ip" {
  description = "bastion IP address"
  type        = "string"
  default     = ""
}

variable "ssh_public_key" {
  description = "local path to the authorized SSH public key to connect to the created VMs"
  type        = "string"
}

variable "ssh_private_key" {
  description = "local path to the authorized SSH private key to connect to the created VMs"
  type        = "string"
}
