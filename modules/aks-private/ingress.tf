resource "azurerm_public_ip" "ingress" {
  name                = "${var.name}-${var.env}-ingress"
  location            = "${var.region}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}
