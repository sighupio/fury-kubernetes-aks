resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-${var.env}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["${var.vpc_cidr}"]
}

// Public subnet setup
resource "azurerm_subnet" "public" {
  name                      = "${var.name}-${var.env}-public"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.main.name}"
  address_prefix            = "${var.public_subnet_cidr}"
  network_security_group_id = "${azurerm_network_security_group.public.id}"
  route_table_id            = "${azurerm_route_table.public.id}"
  service_endpoints         = "${var.public_subnet_endpoints}"
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.name}-${var.env}-public"
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
    destination_address_prefix = "${var.public_subnet_cidr}"
  }

  security_rule {
    name                       = "ingress-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "${azurerm_public_ip.ingress.ip_address}"
  }

  security_rule {
    name                       = "ingress-https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "${azurerm_public_ip.ingress.ip_address}"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = "${azurerm_subnet.public.id}"
  network_security_group_id = "${azurerm_network_security_group.public.id}"
}

resource "azurerm_route_table" "public" {
  name                = "${var.name}-${var.env}-public"
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

resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = "${azurerm_subnet.public.id}"
  route_table_id = "${azurerm_route_table.public.id}"
}
