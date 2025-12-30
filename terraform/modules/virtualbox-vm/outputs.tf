output "vm_name" {
  description = "Name of the deployed VM"
  value       = local.vm_full_name
}

output "vm_info" {
  description = "VM information and access details"
  value = {
    vm_name           = local.vm_full_name
    bridged_adapter   = var.bridged_adapter
    access_note       = "VM is running on bridged network ${var.bridged_adapter}. Use VBoxManage or your configured SSH keys to access."
    get_ip_command    = "VBoxManage guestproperty get ${local.vm_full_name} /VirtualBox/GuestInfo/Net/0/V4/IP"
    stop_command      = "VBoxManage controlvm ${local.vm_full_name} poweroff"
    start_command     = "VBoxManage startvm ${local.vm_full_name} --type headless"
  }
}
