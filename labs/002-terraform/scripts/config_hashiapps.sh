#!/bin/bash

# Terraform variables will be "injected" via interpolation and data source configuration in main template
export IS_SERVER="${is_server}"

## Required for Cluster Servers only [Consul, Vault, Nomad] - value ignored/unused for agents
export CLUSTER_VM_COUNT=${cluster_vm_count}

# Required for Cloud Auto Join
export AZURE_SUBSCRIPTION_ID="${azure_subscription_id}"
export AZURE_TENANT_ID="${azure_tenant_id}"

## Required for all Servers/Agents
export CONSUL_VMSS_NAME="${consul_vmss_name}"
export CONSUL_VMSS_RG="${consul_vmss_rg}"
export CONSUL_DC_NAME="${consul_dc_name}"
export CONSUL_ENCRYPT_KEY="${consul_encrypt_key}"

## Consul Cloud Auto Join Credentials
export CONSUL_CLOUD_AUTO_JOIN_CLIENT_ID="${consul_cloud_auto_join_client_id}"
export CONSUL_CLOUD_AUTO_JOIN_CLIENT_SECRET="${consul_cloud_auto_join_client_secret}"
## See also CONSUL_VMSS_NAME and CONSUL_VMSS_RG as requirements

## Required for Consul Server
export CONSUL_MASTER_TOKEN="${consul_master_token}"

## Required if Vault Server
export AKV_VAULT_NAME="${azure_key_vault_name}"
export AKV_KEY_NAME="${azure_key_vault_shamir_key_name}"

export VAULT_KEY_SHARES="${vault_key_shares}"
export VAULT_KEY_THRESHOLD="${vault_key_threshold}"
export VAULT_PGP_KEYS="${vault_pgp_keys}"
export VAULT_RECOVERY_KEY_BLOB_STORE_URI="${Vvault_recovery_key_blob_store_uri}"
export VAULT_CONSUL_STORAGE_TOKEN="${vault_consul_storage_token}"


## Required if Nomad Server or Agent
export NOMAD_ENCRYPT_KEY="${nomad_encrypt_key}"

## Required for all
export ADMINUSER="${admin_user_name}"

export TEMP_JSON_FILE="/tmp/temp.json"
export CONSUL_CONFIG_DIR="/opt/consul/config"
export VAULT_CONFIG_DIR="/opt/vault/config"
export NOMAD_CONFIG_DIR="/opt/nomad/config"

########################
### Helper Functions ###
########################
### For non-worker nodes (Consul, Vault or Nomad Masters Control Servers) - remove docker.  Called in respective $hashiapp-server functions
uninstall_docker() {
  sudo apt-get purge -y docker-ce
  sudo rm -rf /var/lib/docker
  sudo groupdel docker
  sudo rm -rf /var/run/docker.sock
  sudo rm /usr/bin/docker
}

### Remove the hashiapps not required for respective server types (e.g. Consul doesn't need vault or nomad agents installed)
disable_hashiapp() {
  sudo rm -rf "/opt/$1" || true
  sudo rm "/etc/systemd/system/$1.service" || true
}

### Set file permissions and enable service for HashiApp [consul, vault, nomad]
enable_hashiapp() {
  sudo usermod -aG "$1" "$ADMINUSER" 2>&1 | sudo tee /opt/usermod.txt
  sudo chown -R $1:$1 /opt/$1
  sudo chmod -R 640 /opt/$1
  sudo chmod u+x /opt/$1/bin/$1

  sudo systemctl enable $1
  sudo systemctl restart $1
}

#############################
#### Consul Agent basics ####
#############################
configure_consul_agent() {
  ## Add Consul default settings to all worker and all server types (Consul, Vault, Nomad)
  jq \
    --arg datacenter $CONSUL_DC_NAME \
    '.datacenter = $datacenter' \
    "$CONSUL_CONFIG_DIR/consul.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/consul.json"

  ## Cloud Auto Join
  # jq \
  #   --arg tenant_id $AZURE_TENANT_ID \
  #   --arg client_id $AZURE_CLIENT_ID \
  #   --arg client_secret $AZURE_CLIENT_SECRET \
  #   --arg consul_vmss_name $CONSUL_VMSS_NAME \
  #   --arg consul_vmss_rg $CONSUL_VMSS_RG \
  #   '.retry_join = ["provider=azure tenant_id=$tenant_id client_id=$client_id secret_access_key=$client_secret subscription_id=$subscription_id vms_scale_set=$consul_vmss_name resource_group=$consul_vmss_rg"]' \
  #   "$CONSUL_CONFIG_DIR/consul.json" > \
  #   $TEMP_JSON_FILE && \
  #   mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/consul.json"

  ## Set Consul Agent ACL Token
  # jq \
  #   --arg agent_acl_token $CONSUL_AGENT_TOKEN \
  #   '.acl.tokens.agent = $agent_acl_token' \
  #   "$CONSUL_CONFIG_DIR/acl.json" > $TEMP_JSON_FILE && \
  #   mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/acl.json"

  ## Setup TLS Encrpytion settings
  jq \
    '.auto_encrypt.tls = true' \
    "$CONSUL_CONFIG_DIR/tls.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/tls.json"

  ## Setup RPC Encryption Settings
  jq \
    --arg consul_encrypt_key $CONSUL_ENCRYPT_KEY \
    '.encrypt = $consul_encrypt_key' \
    "$CONSUL_CONFIG_DIR/rpc.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/rpc.json"

  enable_hashiapp "consul"
}

#################################
#### Consul Server specifics ####
#################################
configure_consul_server() {
  uninstall_docker
  disable_hashiapp "vault"
  disable_hashiapp "nomad"

  ## Set agent as Server
  jq \
    '.server = true' \
    "$CONSUL_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/server.json"

  ## Set the expected server numbers for bootstrap
  jq \
    --arg cluster_size $CLUSTER_VM_COUNT \
    '.bootstrap_expect = $cluster_size' \
    "$CONSUL_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/server.json"

  ## Set Consul Master acl token
  jq \
    --arg master_acl_token $CONSUL_MASTER_TOKEN \
    '.acl.tokens.master = $master_acl_token' \
    "$CONSUL_CONFIG_DIR/acl.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/acl.json"

  ## Set Server's ability to generate and send TLS certs to Agents
  jq \
    '.auto_encrypt.allow_tls = true | verify_incoming = true' \
    "$CONSUL_CONFIG_DIR/tls.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/tls.json"

  ## Set Server ports
  jq \
    '.ports.http = -1 | .ports.https = 8501' \
    "$CONSUL_CONFIG_DIR/ports.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/ports.json"
  
  ## Set Server TLS Values
  jq \
    '.cert_file = "/opt/consul/config/ssl/dc1-server-consul-0.pem"' \
    "$CONSUL_CONFIG_DIR/tls.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/tls.json"
  
  jq \
    '.key_file = "/opt/consul/config/ssl/dc1-server-consul-0-key.pem"' \
    "$CONSUL_CONFIG_DIR/tls.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/tls.json"
  
  ## Consul Connect Settings
  jq \
    '.connect.ca_provider = "consul" | .connect.ca_config.private_key = "/opt/consul/config/ssl/consul-agent-ca-key.pem" | .connect.ca_config.root_cert = "/opt/consul/config/ssl/consul-agent-ca.pem"' \
    $CONSUL_CONFIG_DIR/connect.json > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$CONSUL_CONFIG_DIR/connect.json"

  ## export consul token to interact with Consul CLI
  echo "export CONSUL_HTTP_TOKEN='$CONSUL_MASTER_TOKEN'" >> /home/$ADMINUSER/.bashrc
  echo "export CONSUL_CACERT='$CONSUL_CONFIG_DIR/ssl/consul-agent-ca.pem'" >> /home/$ADMINUSER/.bashrc 
  

  configure_consul_agent
}

################################
#### Vault Server specifics ####
################################
configure_vault_server() {
  uninstall_docker
  disable_hashiapp "nomad"
  configure_consul_agent

  # Set Server Config
  jq \
    --arg api_addr $HOSTNAME \
    '.api_addr = "http://$api_addr:8200"' \
    "$VAULT_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/server.json"

  jq \
    --arg cluster_addr $HOSTNAME \
    '.cluster_addr = "http://$cluster_addr:8201"' \
    "$VAULT_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/server.json"

  # Set Consul as the Vault Store
  jq \
    --arg vault_consul_storage_token $VAULT_CONSUL_STORAGE_TOKEN \
    '.storage.consul.token = $vault_consul_storage_token' \
    "$VAULT_CONFIG_DIR/storage.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/storage.json"

  # Set Azure Cloud Auto Unseal
  jq \
    --arg azure_tenant_id $AZURE_TENANT_ID \
    '.seal.azurekeyvault.tenant_id = $azure_tenant_id' \
    "$VAULT_CONFIG_DIR/auto_unseal.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/auto_unseal.json"
  
  jq \
    --arg azure_vault_name $AKV_VAULT_NAME \
    '.seal.azurekeyvault.vault_name = $azure_vault_name' \
    "$VAULT_CONFIG_DIR/auto_unseal.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/auto_unseal.json"
  
  jq \
    --arg azure_key_name $AKV_KEY_NAME \
    '.seal.azurekeyvault.key_name = $azure_key_name' \
    "$VAULT_CONFIG_DIR/auto_unseal.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$VAULT_CONFIG_DIR/auto_unseal.json"

  enable_hashiapp "vault"

  sleep 120

sudo vault operator init \
  -address="http://127.0.0.1:8200" \
  -recovery-shares=$VAULT_KEY_SHARES \
  -recovery-threshold=$VAULT_KEY_THRESHOLD \
  -recovery-pgp-keys=$VAULT_PGP_KEYS 2>&1 | sudo tee /opt/vault_recovery_keys.txt

export RECOVERY_KEYS=($(head -n -5 /opt/vault_recovery_keys.txt | awk '{ print $4 }'))
export VAULT_ROOT_TOKEN=$${RECOVERY_KEYS[-1]}
export users=()

unset 'RECOVERY_KEYS[$${#RECOVERY_KEYS[@]}-1]'

rm /opt/vault_recovery_keys.txt

sudo echo "export VAULT_ADDR='http://127.0.0.1:8200'" >> /home/$ADMINUSER/.bashrc
sudo echo "export VAULT_TOKEN='$VAULT_ROOT_TOKEN'" >> /home/$ADMINUSER/.bashrc

OLDIFS=$IFS
IFS=","
keybase=($VAULT_PGP_KEYS)
IFS=$OLDIFS

for index in "$${!keybase[@]}"; do
  users+=($(echo $${keybase[index]} | awk -F: '{print $2}'))
done

for index in "$${!RECOVERY_KEYS[@]}"; do
  echo "$${users[$index]}: $${RECOVERY_KEYS[$index]}" >> /opt/vault_recovery_keys.txt
done

Setup Consul Secrets Backend/Engine
sudo vault secrets enable consul
sudo vault write consul/config/access \
  -address="127.0.0.1:8500" \
  -token=$CONSUL_MASTER_TOKEN

}

###############################
#### Nomad Common Settings ####
###############################
configure_nomad_common() {
  disable_hashiapp "vault"
  configure_consul_agent

  enable_hashiapp "nomad"
}

####################################
#### Nomad Client ONLY settings ####
####################################

configure_nomad_client() {
  jq \
    '.client.enabled = true' \
    "$NOMAD_CONFIG_DIR/client.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$NOMAD_CONFIG_DIR/client.json"
  configure_nomad_common
}


####################################
#### Nomad Server ONLY settings ####
####################################
configure_nomad_server() {
  uninstall_docker

  ## Nomad Server Config  
  jq \
    '.server.enabled = true' \
    "$NOMAD_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$NOMAD_CONFIG_DIR/server.json"
  
  jq \
    --arg cluster_size $CLUSTER_VM_COUNT \
    '.server.bootstrap_expect = $cluster_size' \
    "$NOMAD_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$NOMAD_CONFIG_DIR/server.json"
  
  jq \
    --arg nomad_encrypt_key $NOMAD_ENCRYPT_KEY \
    '.server.encrypt = $nomad_encrypt_key' \
    "$NOMAD_CONFIG_DIR/server.json" > \
    $TEMP_JSON_FILE && \
    mv $TEMP_JSON_FILE "$NOMAD_CONFIG_DIR/server.json"

  configure_nomad_common
}


###############################
### Server or Worker setup ####
###############################
case $IS_SERVER in
  consul)
    configure_consul_server
    ;;
  vault)
    configure_vault_server
    ;;
  nomad)
    configure_nomad_server
    ;;
  *)
    # If it's not a consul, vault or nomad server...it's default a worker (aka nomad agent)...
    configure_nomad_client
    ;;
esac