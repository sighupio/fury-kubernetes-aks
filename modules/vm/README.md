# VM
Terraform module for Azure resource provisioning

-----

### Purpose

Module `vm` pairs with module `network` to do the following:
  - provision a variable amount of VMs within the input subnet
  - modifiable disk sizes, VM sizes, images, etc.
  - optional public IPs for the VMs
  - optional list of additional security rules for the VMs
  - optional list of role assignments for the VMs
  - optional list of storage disks for the VMs

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

module "vm" {
  source = "./modules/vm"

  name    = "projectX"
  env     = "prod"
  vm_name = "gitlab"

  vm_image = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  resource_group_name         = "${azurerm_resource_group.main.name}"
  subnet_id                   = "${module.network.subnet_id}"
  network_security_group_name = "${module.network.main_network_security_group_name}"
  bastion_ip                  = "${module.network.bastion_public_ip[0]}"
  vm_count                    = 3
  vm_size                     = "Standard_D2s_v3"
  storage_os_disk_size        = 50
  enable_public_ip            = true

  security_rules = [
    {
      name                   = "inbound-ssh"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = "22"
      source_address_prefix  = "*"
    },
  ]

  role_assignments = [
    {
      scope                = "${azurerm_resource_group.main.id}"
      role_definition_name = "AcrPush"
    },
    {
      scope                = "${azurerm_resource_group.main.id}"
      role_definition_name = "AcrPull"
    },
  ]

  vm_disks = [
    {
      storage_account_type = "StandardSSD_LRS"
      disk_size_gb         = 100
    },
  ]
  ssh_public_key  = "../secret/ssh-user.pub"
  ssh_private_key = "../secret/ssh-user"
}
```
