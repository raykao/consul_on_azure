data "template_file" "hashiconfig" {
  template = "${file("${path.module}/scripts/config_hashiapps.sh")}"
  vars {
    is_server = "${local.hashiapp}"

    cluster_vm_count = "${local.cluster_vm_count}"
    azure_subscription_id = "${data.azurerm_subscription.primary.id}"
    azure_tenant_id = "${data.azurerm_client_config.current.tenant_id}"
    
    consul_vmss_name = "${local.consul_vmss_name}"
    consul_vmss_rg = "${local.consul_vmss_rg}"
    consul_dc_name = "${local.consul_dc_name}"
    consul_encrypt_key = "${local.consul_encrypt_key}"
    consul_master_acl_token = "${local.consul_master_acl_token}"

    azure_key_vault_name = "${local.azure_key_vault_name}"
    vault_shamir_key_name = "${local.vault_shamir_key_name}"
    
    vault_key_shares = "${local.vault_key_shares}"
    vault_key_threshold = "${local.vault_key_threshold}"
    vault_pgp_keys = "${local.vault_pgp_keys}"

    nomad_encrypt_key = "${local.nomad_encrypt_key}"
    
    admin_user_name = "${local.admin_user_name}"
  }
}