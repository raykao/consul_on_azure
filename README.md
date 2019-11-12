# Consul on Azure

## Packer

Create a custom managed image for use as an Azure VM or VM Scale Set (VMSS).

The goal of this section is to create a custom base image that will have all the necessary binaries and tools to run Consul out of the box.  We can store all of the generic settings and configuration files here as well and allow for only the values/settings that are only known or configurable at provisioning time to be set when we deploy the VM/VMSS.  For provisioning time configuration we will be leveraging Terraform, however you can also use Azure Resource Manager (ARM) templates as well.

## Bootstrapping Checklist
- Consul Server Node (Masters) IP Addresses
  - Can be static:
    - Known list of static IP addresses assigned to Server (Master) Nodes ("Consul Servers")
    - Scope down to a specific Subnet Address Space
      - Consul best practice requires a cluster size of 3-5 for production
      - Save 1 IP address for cluster VM rolling upgrade (Optional)
      - Minium subnet size: /28 (16 IPs total in address space)
        - 5 (cluster VMs) 
        - 5 ([Azure Reserved IPs](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq#what-address-ranges-can-i-use-in-my-vnets))
        - 6 Free/Available IPs
  - Can be dynamic:
    - Consul's Cloud-Auto-Join Feature
    - Use custom script leveraging Service Principals or MSI and delegate read role on Consul Server/Master Subnet
- [Consul Gossip Protocol Encrypt Key](https://www.consul.io/docs/agent/encryption.html#gossip-encryption)
  - 32 Bytes, Base64 encoded
- [ACL Tokens](https://learn.hashicorp.com/consul/security-networking/production-acls)
  - Used for Consul Access Control (RBAC)
  - Master Tokens
    - Used only on Server/Master Nodes
    - Global/Super User Token
    - Established when there is a Leader Server elected (Master Token Policy Auto Applied)
    - Can be pre-seeded (generated) and shared on each Server Node
      - Caveats:
        - Will be a known key passed around - how to restrict access?
        - Blast radius of the compromised token affects all servers and must be rotated out on all servers
    - Can also be unique to each server and used when that node is elected to Primary
      - Caveats:
        - How to get the ACL Token value out/stored to run admin/operator work?
        - Blast radius is reduced to just the single affected server (cull affected node)
        - Can force a key rotation by electing a new leader
  - Agent Tokens
    - Required for all Nodes (Server and Agent Nodes)
    - Used to perform Agent/Node level operations (sync data)
    - ACL Policy Must be unique/scoped to just that Node (Leverage ```uuidgen```)
    - Caveats:
      - How to apply Node Policy?
      -
    