resource "azurerm_user_assigned_identity" "hashiapp_msi" {
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location            = "${azurerm_resource_group.hashicluster.location}"

  name = "${var.hashiapp}-${random_string.msi_name.result}-msi"

  tags {
    hashi = "vmssreader"
  }
}

resource "azurerm_role_assignment" "test" {
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Reader"
  principal_id         = "${azurerm_user_assigned_identity.hashiapp_msi.principal_id}"
}
