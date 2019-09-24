resource "azurerm_public_ip" "vm" {
  count               = "${var.enable_public_ip ? var.vm_count : 0}"
  name                = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  allocation_method   = "Static"
  domain_name_label   = "${var.domain_name_label}-${count.index+1}"
}

resource "azurerm_network_interface" "vm" {
  count                     = "${var.vm_count}"
  name                      = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
  location                  = "${data.azurerm_resource_group.main.location}"
  resource_group_name       = "${data.azurerm_resource_group.main.name}"
  network_security_group_id = "${data.azurerm_network_security_group.main.id}"
  enable_ip_forwarding      = "${var.enable_ip_forwarding}"

  ip_configuration {
    name                          = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${var.enable_public_ip ? element(concat(azurerm_public_ip.vm.*.id, list("")), var.enable_public_ip * count.index) : ""}" #hacky workaround
  }
}

resource "azurerm_virtual_machine" "vm" {
  count                 = "${var.vm_count}"
  name                  = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
  location              = "${data.azurerm_resource_group.main.location}"
  resource_group_name   = "${data.azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.vm.*.id[count.index]}"]
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "${var.vm_image["publisher"]}"
    offer     = "${var.vm_image["offer"]}"
    sku       = "${var.vm_image["sku"]}"
    version   = "${var.vm_image["version"]}"
  }

  storage_os_disk {
    name              = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "${var.storage_os_disk_size}"
  }

  os_profile {
    computer_name  = "${var.name}-${var.env}-${var.vm_name}-${count.index+1}"
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

resource "azurerm_managed_disk" "vm" {
  count                = "${length(var.vm_disks) * var.vm_count}"
  name                 = "${var.name}-${var.env}-${var.vm_name}-${(count.index % var.vm_count) + 1}-${count.index + 1}"
  location             = "${data.azurerm_resource_group.main.location}"
  resource_group_name  = "${data.azurerm_resource_group.main.name}"
  storage_account_type = "${lookup(var.vm_disks[count.index % length(var.vm_disks)], "storage_account_type")}"
  create_option        = "Empty"
  disk_size_gb         = "${lookup(var.vm_disks[count.index % length(var.vm_disks)], "disk_size_gb")}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm" {
  count              = "${length(var.vm_disks) * var.vm_count}"
  managed_disk_id    = "${azurerm_managed_disk.vm.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.vm.*.id[count.index % var.vm_count]}"
  lun                = "${(count.index % length(var.vm_disks)) + 1}"
  caching            = "ReadWrite"
}

resource "azurerm_role_assignment" "vm" {
  count                = "${length(var.role_assignments) * var.vm_count}"
  scope                = "${lookup(var.role_assignments[count.index % length(var.role_assignments)], "scope")}"
  role_definition_name = "${lookup(var.role_assignments[count.index % length(var.role_assignments)], "role_definition_name")}"
  principal_id         = "${element(azurerm_virtual_machine.vm.*.identity.0.principal_id, count.index % var.vm_count)}"
}

resource "azurerm_network_security_rule" "vm" {
  count                  = "${length(var.security_rules) * var.vm_count}"
  name                   = "${var.name}-${var.env}-${var.vm_name}-${(count.index % var.vm_count) + 1}-${count.index + 1}-${lookup(var.security_rules[count.index % length(var.security_rules)], "name")}"
  priority               = "${lookup(var.security_rules[count.index % length(var.security_rules)], "priority") + count.index + 1}"
  direction              = "${lookup(var.security_rules[count.index % length(var.security_rules)], "direction")}"
  access                 = "${lookup(var.security_rules[count.index % length(var.security_rules)], "access")}"
  protocol               = "${lookup(var.security_rules[count.index % length(var.security_rules)], "protocol")}"
  source_port_range      = "${lookup(var.security_rules[count.index % length(var.security_rules)], "source_port_range")}"
  destination_port_range = "${lookup(var.security_rules[count.index % length(var.security_rules)], "destination_port_range")}"
  source_address_prefix  = "${lookup(var.security_rules[count.index % length(var.security_rules)], "source_address_prefix")}"

  destination_address_prefixes = [
    "${compact(list(azurerm_network_interface.vm.*.private_ip_address[count.index % var.vm_count],
    var.enable_public_ip ? element(concat(azurerm_public_ip.vm.*.ip_address,
    list("")), var.enable_public_ip * (count.index % var.vm_count)) : ""))}",
  ] # hacky workaround

  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${var.network_security_group_name}"
}
