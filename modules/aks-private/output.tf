output "kubeconfig" {
  value = "${azurerm_kubernetes_cluster.main.kube_admin_config_raw}"
}

output "docker-login" {
  value = "docker login ${azurerm_container_registry.main.login_server} -u ${azuread_service_principal.acr.application_id} -p ${azuread_service_principal_password.acr.value}"
}

locals {
  ingress-patch = <<EOF
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: ${azurerm_resource_group.main.name}
  name: ingress-nginx
spec:
  loadBalancerIP: ${azurerm_public_ip.ingress.ip_address}
EOF
}

output "ingress-patch" {
  value = "${local.ingress-patch}"
}

locals {
  inventory = <<EOF
bastion ansible_host="${azurerm_public_ip.bastion.ip_address}"

[gated]

[gated:children]
build

[build]
${join("\n", azurerm_network_interface.build.*.private_ip_address)}

[all:vars]
ansible_ssh_private_key_file="../secrets/terraform"
ansible_user=ubuntu

[gated:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q -i ../secrets/terraform ubuntu@${azurerm_public_ip.bastion.ip_address}"'
EOF
}

output "inventory" {
  value = "${local.inventory}"
}
