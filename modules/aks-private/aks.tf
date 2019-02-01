resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.name}-${var.env}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  dns_prefix          = "${var.name}-${var.env}"

  # agent_pool_profile {
  #   name            = "infra"
  #   count           = "${var.infra-node-number}"
  #   vm_size         = "${var.infra-node-type}"
  #   max_pods        = 100
  #   os_type         = "Linux"
  #   os_disk_size_gb = 80
  #   vnet_subnet_id  = "${azurerm_subnet.public.id}"
  # }

  agent_pool_profile {
    name            = "app"
    count           = "${var.app-node-number}"
    vm_size         = "${var.app-node-type}"
    max_pods        = 100
    os_type         = "Linux"
    os_disk_size_gb = 80
    vnet_subnet_id  = "${azurerm_subnet.public.id}"
  }
  service_principal {
    client_id     = "${azuread_application.aks.application_id}"
    client_secret = "${azuread_service_principal_password.aks.value}"
  }
  kubernetes_version = "${var.kubernetes-version}"
  addon_profile {
    http_application_routing {
      enabled = false
    }
  }
  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = "${var.ssh_public_key}"
    }
  }
  network_profile {
    network_plugin = "azure"
  }
  role_based_access_control {
    enabled = true

    azure_active_directory {
      client_app_id     = "${var.ad-client-app-id}"
      server_app_id     = "${var.ad-server-app-id}"
      server_app_secret = "${var.ad-server-app-secret}"
    }
  }
  tags {
    Environment = "${var.env}"
    ClusterName = "${var.name}-${var.env}"
  }
}

resource "azurerm_container_registry" "main" {
  name                = "${var.name}${var.env}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  sku                 = "Standard"
  admin_enabled       = false
}
