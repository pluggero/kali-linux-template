##################################################################################
# VARIABLE DEFINITIONS
##################################################################################

# HTTP Settings
http_interface                      = "pentap0"

# Virtual Machine Settings
vm_guest_os_version                 = "2025.1c"
vm_boot_wait                        = "10s"
vm_cpu_core                         = 4
vm_mem_size                         = 6144 # Must be at least 6144 MB for /tmp to be large enough
vm_root_shutdown_command            = "/sbin/shutdown -hP now"
vm_disk_size                        = 60000
vm_ssh_port                         = 22
vm_ssh_timeout                      = "3600s"
vm_ssh_username                     = "kali"
vm_ssh_temp_password                = "KaliSuperSecureTemp!"

# VirtualBox Settings
vbox_vm_headless                    = true
vbox_guest_additions                = "disable"
vbox_output_format                  = "ovf"

# VirtualBox Post-Processing Settings
vbox_post_cpu_core                  = 3
vbox_post_mem_size                  = 8192
vbox_post_bridged_adapter           = "pentap0"
vbox_post_graphics                  = "vmsvga"
vbox_post_vram                      = 256
vbox_post_accelerate_3d             = "off"
vbox_post_clipboard_mode            = "bidirectional"
vbox_post_shared_folder_name        = "linux_vm"
vbox_post_shared_folder_path        = "documents/shared/linux_vm"
vbox_post_shared_folder_mount_point = "/mnt/shared"
