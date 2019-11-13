
resource "azurerm_virtual_machine_scale_set" "hashicluster" {
  name = "${local.vmss_name}"
  resource_group_name = "${azurerm_resource_group.hashicluster.name}"
  location = "${azurerm_resource_group.hashicluster.location}"
  upgrade_policy_mode = "Manual"

  sku {
    capacity = "${var.cluster_vm_count}"
    name = "${var.cluster_vm_size}"
    tier = "Standard"
  }

  identity {
    type = "UserAssigned"
    identity_ids = ["${azurerm_user_assigned_identity.hashiapp_msi.id}"]
  }

  os_profile {
    computer_name_prefix = "hashi${var.hashiapp}"
    admin_username = "${var.admin_user_name}"
    custom_data = "${data.template_file.hashiconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${local.admin_user_name}/.ssh/authorized_keys"
      key_data = "${local.ssh_public_key}"
    }
  }

  network_profile {
    name = "HashiClusterNetworkProfile"
    primary = true

    ip_configuration {
      primary = true
      name = "HashiClusterIPConfiguration"
      subnet_id = "${azurerm_subnet.hashicluster.id}"
    }
  }

  storage_profile_image_reference {
    id = "${local.managed_image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Premium_LRS"
  }

  tags {
    scaleSetName = "${local.hashiapp}"
  }
}