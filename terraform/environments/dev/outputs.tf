output "vm_name" {
  description = "Name of the deployed VM"
  value       = module.kali_vm.vm_name
}

output "vm_info" {
  description = "VM information and access details"
  value       = module.kali_vm.vm_info
}
