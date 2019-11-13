locals {
  
  hashiapp                        = "${var.hashiapp}"
  vmss_name                       = "${var.vmss_name}"
  resource_group_name             = "${var.resource_group_name}"
  resource_group_location         = "${var.resource_group_location}"
  cluster_vm_count                = "${var.cluster_vm_count}"
  managed_image_id                = "${var.cluster_vm_image_reference}"

  admin_user_name                 = "${var.admin_user_name}"
  ssh_public_key                  = "${var.ssh_public_key}"

  consul_dc_name                  = "${var.consul_dc_name}"
  consul_vmss_name                = "${var.consul_vmss_name}"
  consul_vmss_rg                  = "${var.consul_vmss_rg}"
  consul_encrypt_key              = "${var.consul_encrypt_key != "" ? var.consul_encrypt_key : base64encode(random_string.consul_encrypt.result)}"
  consul_master_acl_token         = "${var.consul_master_acl_token != "" ? var.consul_master_acl_token : random_uuid.consul_master_acl_token.result}"

  azure_key_vault_name            = "${var.azure_key_vault_name != "" ? var.azure_key_vault_name : random_pet.keyvault.id}"
  vault_shamir_key_name           = "${var.vault_shamir_key_name != "" ? var.vault_shamir_key_name : random_string.vault_shamir_key_name.result}"
  
  vault_key_shares                = "${var.vault_key_shares}"
  vault_key_threshold             = "${var.vault_key_threshold}"
  vault_pgp_keys                  = "${var.vault_pgp_keys}"
  
  key_vault_count                 = "${var.hashiapp == "vault" ? 1 : 0}"

  vault_service_endpoints         = "${var.hashiapp == "vault" ? "Microsoft.KeyVault" : ""}"
  
  nomad_encrypt_key               = "${var.nomad_encrypt_key != "" ? var.nomad_encrypt_key : base64encode(random_string.nomad_encrypt.result)}"
}