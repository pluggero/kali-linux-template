##################################################################################
# VARIABLE DEFINITIONS
##################################################################################

# HTTP Settings
http_interface                      = "pentap0"
preseed_file                        = "preseed.cfg"
preseed_checksum                    = "e6e6c4c64900548ef00978b0815fcd00"

# Packer Settings
packer_input_dir                    = "inputs"
packer_output_dir                   = "outputs"

# Ansible Settings
ansible_vault_password_file         = "../ansible/inventory/group_vars/all/.vault_pass"
ansible_collections_path            = "../ansible/collections"
ansible_roles_path                  = "../ansible/roles"
ansible_requirements_file           = "../ansible/requirements.yml"
ansible_playbook_init               = "../ansible/playbooks/provision-init.yml"
ansible_playbook_provision          = "../ansible/playbooks/provision.yml"

# Virtual Machine Settings
vm_guest_os_version                 = "2025.4"
vm_boot_wait                        = "10s"
vm_cpu_core                         = 4
vm_mem_size                         = 6144 # Must be at least 6144 (MB) for /tmp to be large enough
vm_root_shutdown_command            = "/sbin/shutdown -hP now"
vm_disk_size                        = 60000 # Must be at least 16000 (MB) for the Kali installation to succeed
vm_ssh_port                         = 22
vm_ssh_timeout                      = "3600s"
vm_hostname                         = "kali"
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
