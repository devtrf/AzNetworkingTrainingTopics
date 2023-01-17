output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm1.public_ip_address
}

output "tls_private_key1" {
  value     = tls_private_key.vm_ssh1.private_key_pem
  sensitive = true
}

output "tls_private_key2" {
  value     = tls_private_key.vm_ssh2.private_key_pem
  sensitive = true
}