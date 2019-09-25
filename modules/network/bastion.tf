resource "azurerm_subnet" "bastion" {
  count                     = "${var.bastion_count > 0 ? 1 : 0}"
  name                      = "${var.name}-${var.env}-bastion"
  resource_group_name       = "${data.azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.network.name}"
  address_prefix            = "${cidrsubnet(var.vnet_cidr, 1, 1)}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"
  route_table_id            = "${azurerm_route_table.bastion.0.id}"
}

resource "azurerm_network_security_group" "bastion" {
  count               = "${var.bastion_count > 0 ? 1 : 0}"
  name                = "${var.name}-${var.env}-bastion"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
}

resource "azurerm_network_security_rule" "bastion-subnet-inbound-ssh" {
  count                       = "${var.bastion_enable_ssh * var.bastion_count > 0 ? 1 : 0}"
  name                        = "bastion-subnet-inbound-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${data.azurerm_resource_group.main.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_network_security_rule" "bastion-subnet-inbound-openvpn" {
  count                       = "${var.bastion_enable_openvpn * var.bastion_count > 0 ? 1 : 0}"
  name                        = "bastion-subnet-inbound-openvpn"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "1194"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${data.azurerm_resource_group.main.name}"
  network_security_group_name = "${azurerm_network_security_group.bastion.name}"
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  count                     = "${var.bastion_count > 0 ? 1 : 0}"
  subnet_id                 = "${azurerm_subnet.bastion.id}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"
}

resource "azurerm_route_table" "bastion" {
  count               = "${var.bastion_count > 0 ? 1 : 0}"
  name                = "${var.name}-${var.env}-bastion"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
}

resource "azurerm_route" "bastion-local" {
  count               = "${var.bastion_count > 0 ? 1 : 0}"
  name = "${var.name}-${var.env}-bastion-local"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  route_table_name = "${azurerm_route_table.bastion.0.name}"
  address_prefix = "${var.vnet_cidr}"
  next_hop_type = "VnetLocal"
}

resource "azurerm_route" "bastion-internet" {
  count               = "${var.bastion_count > 0 ? 1 : 0}"
  name = "${var.name}-${var.env}-bastion-internet"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  route_table_name = "${azurerm_route_table.bastion.0.name}"
  address_prefix = "0.0.0.0/0"
  next_hop_type = "Internet"
}

resource "azurerm_subnet_route_table_association" "bastion" {
  count          = "${var.bastion_count > 0 ? 1 : 0}"
  subnet_id      = "${azurerm_subnet.bastion.id}"
  route_table_id = "${azurerm_route_table.bastion.0.id}"
}

resource "azurerm_public_ip" "bastion" {
  count               = "${var.bastion_count}"
  name                = "${var.name}-${var.env}-bastion-${count.index+1}"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "bastion" {
  count                     = "${var.bastion_count}"
  name                      = "${var.name}-${var.env}-bastion-${count.index+1}"
  location                  = "${data.azurerm_resource_group.main.location}"
  resource_group_name       = "${data.azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"

  ip_configuration {
    name                          = "${var.name}-${var.env}-bastion-${count.index+1}"
    subnet_id                     = "${azurerm_subnet.bastion.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.*.id[count.index]}"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  count                 = "${var.bastion_count}"
  name                  = "${var.name}-${var.env}-bastion-${count.index+1}"
  location              = "${data.azurerm_resource_group.main.location}"
  resource_group_name   = "${data.azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion.*.id[count.index]}"]
  vm_size               = "${var.bastion_node_size}"

  delete_os_disk_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "${var.bastion_node_image["publisher"]}"
    offer     = "${var.bastion_node_image["offer"]}"
    sku       = "${var.bastion_node_image["sku"]}"
    version   = "${var.bastion_node_image["version"]}"
  }

  storage_os_disk {
    name              = "${var.name}-${var.env}-bastion-${count.index+1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 40
  }

  os_profile {
    computer_name  = "${var.name}-${var.env}-bastion-${count.index+1}"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${file(var.ssh_public_key)}"
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }
}
