# Network
Terraform module for Azure resource provisioning

-----

### Purpose

This module sets up the following on Azure
 - virtual network
 - two subnets (main and bastion host subnets)
 - route tables
 - basic security rules
 - variable amount of bastion hosts

*NOTE: This module pairs well with the `vm` module from this repository*

-----

### Example Usage

```
module "network" {
  source = "./modules/network"

  name                = "projectX"
  env                 = "prod"
  vnet_cidr           = "10.0.0.0/16"
  resource_group_name = "${azurerm_resource_group.main.name}"

  bastion_node_image = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  ssh_public_key  = "../secret/ssh-user.pub"
  ssh_private_key = "../secret/ssh-user"
}
```
