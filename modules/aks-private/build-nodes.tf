resource "azurerm_subnet" "build" {
  count                     = "${var.build-node-number > 0 ? 1 : 0}"
  name                      = "${var.name}-${var.env}-build"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.main.name}"
  address_prefix            = "${var.build_subnet_cidr}"
  network_security_group_id = "${azurerm_network_security_group.build.id}"
  route_table_id            = "${azurerm_route_table.build.id}"
}

resource "azurerm_network_security_group" "build" {
  count               = "${var.build-node-number > 0 ? 1 : 0}"
  name                = "${var.name}-${var.env}-build"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "bastion-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.bastion_subnet_cidr}"
    destination_address_prefix = "${var.build_subnet_cidr}"
  }
}

resource "azurerm_subnet_network_security_group_association" "build" {
  count                     = "${var.build-node-number > 0 ? 1 : 0}"
  subnet_id                 = "${azurerm_subnet.build.id}"
  network_security_group_id = "${azurerm_network_security_group.build.id}"
}

resource "azurerm_route_table" "build" {
  count               = "${var.build-node-number > 0 ? 1 : 0}"
  name                = "${var.name}-${var.env}-build"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  route {
    name           = "local"
    address_prefix = "${var.vpc_cidr}"
    next_hop_type  = "VnetLocal"
  }

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "build" {
  count          = "${var.build-node-number > 0 ? 1 : 0}"
  subnet_id      = "${azurerm_subnet.build.id}"
  route_table_id = "${azurerm_route_table.build.id}"
}

resource "azurerm_network_interface" "build" {
  count                     = "${var.build-node-number}"
  name                      = "${var.name}-${var.env}-build-${count.index}"
  location                  = "${var.region}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.build.id}"

  ip_configuration {
    name                          = "${var.name}-${var.env}-build-${count.index}"
    subnet_id                     = "${azurerm_subnet.build.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "build" {
  count               = "${var.build-node-number}"
  name                = "${var.name}-${var.env}-build-${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  network_interface_ids = [
    "${element(azurerm_network_interface.build.*.id, count.index)}",
  ]

  vm_size = "${var.build-node-type}"

  delete_os_disk_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.name}-${var.env}-build-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 80
  }

  os_profile {
    computer_name  = "${var.name}-${var.env}-build-${count.index}"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path     = "/home/ubuntu/.ssh/authorized_keys"
    }
  }
}
