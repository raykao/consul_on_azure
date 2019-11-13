terraform {
  required_version = ">= 0.12.13"
}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}


resource "random_string" "consul_encrypt" {
  length = 16
  special = false
}
resource "random_string" "nomad_encrypt" {
  length = 16
  special = false
}

resource "random_uuid" "consul_master_acl_token" {}

resource "random_string" "msi_name" {
  length = 8
  number = false
  special = false
}


resource "random_pet" "keyvault" {
  prefix = "hashi"
}

resource "random_string" "vault_shamir_key_name" {
  length = 16
  special = false
}

resource "azurerm_resource_group" "hashicluster" {
  name     = "${local.resource_group_name}"
  location = "${local.resource_group_location}"
  
  tags {
      hashiapp      = "${local.hashiapp}"
      server_type   = "${local.hashiapp}"
    }
}