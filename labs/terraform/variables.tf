
// COMMON CLUSTER VARIABLES
variable "cluster_vm_count" {
  default = 3
}

variable "cluster_vm_size" {
  default = "Standard_D2s_v3"
}

variable "cluster_vm_image_reference" {
  description = "Required - The Managed Image reference URI."
}

variable "admin_user_name" {
  default = "hashiadmin"
}

variable "ssh_public_key" {
  description = "The SSH key to install for the admin user."
}

variable "vnet_name" {
  description = "Required - needed to join a network - will not bootstrap one."
}

variable "vnet_resource_group_name" {
  description = "Required - need to create subnet"
}

variable "subnet_prefix" {
  description = "Required - subnet address space"
}

variable "vmss_name" {
  default = "workernode"
}

variable "resource_group_name" { 
  description = "Requied - The resource group to deploy into"
}

variable "resource_group_location" { 
  description = "Required - The DC location to deploy to"
}

variable "hashiapp" {
  default = "workernode"
}

// Consul Agent Specific Info
variable "consul_vmss_name" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_name' to get the value."
}

variable "consul_vmss_rg" {
  description = "Required - cluster needs the Azure VMSS Name and Resource group of the Consul Server Cluster. You can query the Outputs for 'consul_vmss_rg' to get the value."
}

variable "consul_dc_name" {
  description = "The name of the Consul DC being deployed."
}

variable "consul_encrypt_key" {
  description = "Optional - Supply the initial Consul Gossip Encryption Key or one will be auto generated to bootstrap the cluster.  You can query the Outputs for 'consul_encrypt_key' to get the value."
}

// CONSUL SERVER SPECIFIC
variable "consul_master_acl_token" {
  default = ""
}

// VAULT SPECIFIC CONFIGS
variable "azure_key_vault_name" {
  description = "Required only for Vault Servers - Name of Azure Key Vault to store Shamir Secrets into."
  default = ""
}

variable "shamir_key_name" {
  description = "Required only for Vault Servers - The auto unseal key name stored in Azure Key Vault"
  default = ""
}

variable "vault_key_shares" {
  default = "3"
}

variable "vault_key_threshold" {
  default = "2"
}

variable "vault_pgp_keys" {
  description = "PGP Key locations on the disk path, or keybase names.  Follows this: https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase.html"
  default = "keybase:raykao,keybase:raykao,keybase:raykao"
}

// NOMAD SPECIFIC VARIABLES
variable "nomad_encrypt_key" {
  description = "Optional - Nomad Encrytion Key for Server to Server Gossip.  One will be auto generated if not supplied."
  default = ""
}
