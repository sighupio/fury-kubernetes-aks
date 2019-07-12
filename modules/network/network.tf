resource "azurerm_virtual_network" "network" {
  name                = "${var.name}-${var.env}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${data.azurerm_resource_group.main.location}"
  address_space       = ["${var.vnet_cidr}"]
}

// Main subnet setup
resource "azurerm_subnet" "network" {
  name                      = "${var.name}-${var.env}-main"
  resource_group_name       = "${data.azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.network.name}"
  address_prefix            = "${cidrsubnet(var.vnet_cidr, 1, 0)}"
  network_security_group_id = "${azurerm_network_security_group.network.id}"
  route_table_id            = "${azurerm_route_table.network.id}"
  service_endpoints         = "${var.main_subnet_endpoints}"
}

resource "azurerm_network_security_group" "network" {
  name                = "${var.name}-${var.env}-main"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
}

resource "azurerm_network_security_rule" "bastion-ssh" {
  count                       = "${var.bastion_enable_ssh * var.bastion_count > 0 ? 1 : 0}"
  name                        = "bastion-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${cidrsubnet(var.vnet_cidr, 1, 1)}"
  destination_address_prefix  = "${cidrsubnet(var.vnet_cidr, 1, 0)}"
  resource_group_name         = "${data.azurerm_resource_group.main.name}"
  network_security_group_name = "${azurerm_network_security_group.network.name}"
}

resource "azurerm_subnet_network_security_group_association" "network" {
  subnet_id                 = "${azurerm_subnet.network.id}"
  network_security_group_id = "${azurerm_network_security_group.network.id}"
}

resource "azurerm_route_table" "network" {
  name                = "${var.name}-${var.env}"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"

  route {
    name           = "local"
    address_prefix = "${var.vnet_cidr}"
    next_hop_type  = "VnetLocal"
  }

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "network" {
  subnet_id      = "${azurerm_subnet.network.id}"
  route_table_id = "${azurerm_route_table.network.id}"
}
