# Hashicorp Base Image

The packer ```image.json``` file is the base image used as a generic starting point to start a "Hashistack cluster".  It will install the following Hashicorp Tools:
- Consul
- Vault
- Nomad

It will also install:
- Docker
- jq
- unzip

It will also copy the following Config files:
- /etc/system/system/
  - consul.service
  - nomad.service
  - vault.service
- /opt/
  - consul/
    - config/
      - acl.json
      - connect.json
      - consul.json
      - ports.json
      - rpc.json
      - server.json
      - tls.json
    - ssl/
      - consul-agent-ca.pem
        - To be replaced at pipeline build time with the cert file value stored in an Azure Key Vault 
  - nomad/
    - config/
      - client.json
      - nomad.json
  - vault/
    - config/
      - auto_unseal.json
      - server.json
      - storage.json