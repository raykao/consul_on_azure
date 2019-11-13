resource "azurerm_key_vault" "hashicluster" {
  count                       = "${local.key_vault_count}"
  name                        = "${local.azure_key_vault_name}"
  location                    = "${azurerm_resource_group.hashicluster.location}"
  resource_group_name         = "${azurerm_resource_group.hashicluster.name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
  
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = ["${azurerm_subnet.hashicluster.id}"]
  }
}

resource "azurerm_key_vault_access_policy" "terraform_serviceprincipal" {
  count       = "${local.key_vault_count}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  # vault_name = "${element(azurerm_key_vault.hashicluster.*.name, 0)}"
  # resource_group_name = "${element(azurerm_key_vault.hashicluster.*.resource_group_name, 0)}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${data.azurerm_client_config.current.service_principal_object_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "update",
    "wrapKey",
    "unwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "vault_cluster" {
  count       = "${local.key_vault_count}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  # vault_name = "${element(azurerm_key_vault.hashicluster.*.name, 0)}"
  # resource_group_name = "${element(azurerm_key_vault.hashicluster.*.resource_group_name, 0)}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.hashiapp_msi.principal_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "update",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_key" "generated" {
  # Ensure the policies are in place before trying to create the key to store auto-unseal keys
  depends_on = ["azurerm_key_vault_access_policy.terraform_serviceprincipal", "azurerm_subnet.hashicluster"]
  count     = "${local.key_vault_count}"
  name      = "${local.vault_shamir_key_name}"
  key_vault_id = "${element(azurerm_key_vault.hashicluster.*.id, 0)}"
  key_type  = "RSA"
  key_size  = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}