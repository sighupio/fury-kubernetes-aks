resource "azuread_application" "aks" {
  name = "${var.name}-${var.env}-aks"
}

resource "azuread_service_principal" "aks" {
  application_id = "${azuread_application.aks.application_id}"
}

resource "random_string" "aks" {
  length  = 16
  special = true

  keepers = {
    service_principal = "${azuread_service_principal.aks.id}"
  }
}

resource "azuread_service_principal_password" "aks" {
  service_principal_id = "${azuread_service_principal.aks.id}"
  value                = "${random_string.aks.result}"
  end_date             = "${timeadd(timestamp(), "8760h")}"

  # This stops be 'end_date' changing on each run and causing a new password to be set
  # to get the date to change here you would have to manually taint this resource...
  lifecycle {
    ignore_changes = ["end_date"]
  }
}

data "azurerm_subscription" "main" {}

# Attempt to create a 'least privilidge' role for SP used by AKS
resource "azurerm_role_definition" "main" {
  name        = "aks-master-${var.name}-${var.env}"
  scope       = "${data.azurerm_subscription.main.id}"
  description = "This role provides the required permissions needed by Kubernetes to: Manager VMs, Routing rules, Mount azure files and Read container repositories"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/routeTables/read",
      "Microsoft.Network/routeTables/routes/read",
      "Microsoft.Network/routeTables/routes/write",
      "Microsoft.Network/routeTables/routes/delete",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Storage/storageAccounts/fileServices/fileShare/read",
      "Microsoft.ContainerRegistry/registries/read",
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
    ]

    not_actions = [
      # Deny access to all VM actions, this includes Start, Stop, Restart, Delete, Redeploy, Login, Extensions etc
      "Microsoft.Compute/virtualMachines/*/action",

      "Microsoft.Compute/virtualMachines/extensions/*",
    ]
  }

  assignable_scopes = [
    "${data.azurerm_subscription.main.id}",
  ]
}

resource "azurerm_role_assignment" "aks-master" {
  scope              = "${data.azurerm_subscription.main.id}"
  role_definition_id = "${azurerm_role_definition.main.id}"
  principal_id       = "${azuread_service_principal.aks.id}"

  depends_on = [
    "azurerm_role_definition.main",
  ]
}

resource "azurerm_role_assignment" "aks-network" {
  scope                = "${azurerm_resource_group.main.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.aks.id}"
}

resource "azuread_application" "acr" {
  name = "${var.name}-${var.env}-acr"
}

resource "azuread_service_principal" "acr" {
  application_id = "${azuread_application.acr.application_id}"
}

resource "random_string" "acr" {
  length  = 24
  special = false

  keepers = {
    service_principal = "${azuread_service_principal.acr.id}"
  }
}

resource "azuread_service_principal_password" "acr" {
  service_principal_id = "${azuread_service_principal.acr.id}"
  value                = "${random_string.acr.result}"
  end_date             = "${timeadd(timestamp(), "8760h")}"

  # This stops be 'end_date' changing on each run and causing a new password to be set
  # to get the date to change here you would have to manually taint this resource...
  lifecycle {
    ignore_changes = ["end_date"]
  }
}

resource "azurerm_role_assignment" "acr" {
  scope                = "${azurerm_container_registry.main.id}"
  role_definition_name = "AcrPush"
  principal_id         = "${azuread_service_principal.acr.id}"
}

resource "azurerm_role_assignment" "bastion" {
  scope                = "${azurerm_resource_group.main.id}"
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = "${lookup(azurerm_virtual_machine.bastion.identity[0], "principal_id")}"
}

resource "azurerm_role_assignment" "build" {
  count                = "${var.build-node-number}"
  scope                = "${azurerm_resource_group.main.id}"
  role_definition_name = "AcrPush"
  principal_id         = "${element(azurerm_virtual_machine.build.*.identity.0.principal_id, count.index)}"
}
