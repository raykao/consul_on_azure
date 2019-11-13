resource "azurerm_subnet" "hashicluster" {
  name           = "${local.vmss_name}-subnet"
  virtual_network_name = "${var.vnet_name}"
  resource_group_name  = "${var.vnet_resource_group_name}"
  address_prefix = "${var.subnet_prefix}"
  service_endpoints = ["${local.vault_service_endpoints}"]
}
