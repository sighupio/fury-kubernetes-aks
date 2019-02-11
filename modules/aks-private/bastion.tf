resource "azurerm_subnet" "bastion" {
  name                      = "${var.name}-${var.env}-bastion"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.main.name}"
  address_prefix            = "${var.bastion_subnet_cidr}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"
  route_table_id            = "${azurerm_route_table.bastion.id}"
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.name}-${var.env}-bastion"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "bastion-subnet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = "${azurerm_subnet.bastion.id}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"
}

resource "azurerm_route_table" "bastion" {
  name                = "${var.name}-${var.env}-bastion"
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

resource "azurerm_subnet_route_table_association" "bastion" {
  subnet_id      = "${azurerm_subnet.bastion.id}"
  route_table_id = "${azurerm_route_table.bastion.id}"
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.name}-${var.env}-bastion"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "bastion" {
  name                      = "${var.name}-${var.env}-bastion"
  location                  = "${var.region}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"

  ip_configuration {
    name                          = "${var.name}-${var.env}-bastion"
    subnet_id                     = "${azurerm_subnet.bastion.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = "${var.name}-${var.env}-bastion"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion.id}"]
  vm_size               = "Standard_A2_v2"

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
    name              = "${var.name}-${var.env}-bastion"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 40
  }

  os_profile {
    computer_name  = "${var.name}-${var.env}-bastion"
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
