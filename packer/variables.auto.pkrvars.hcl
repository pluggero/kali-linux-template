##################################################################################
# VARIABLE DEFINITIONS
##################################################################################

# HTTP Settings
http_interface   = "pentap0"
preseed_file     = "preseed.cfg"

# Packer Settings
packer_input_dir  = "inputs"
packer_output_dir = "outputs"

# Ansible Settings
ansible_vault_password_file  = "../ansible/inventory/group_vars/all/.vault_pass"
ansible_collections_path     = "../ansible/collections"
ansible_roles_path           = "../ansible/roles"
ansible_requirements_file    = "../ansible/requirements.yml"
ansible_playbook_init        = "../ansible/playbooks/provision-init.yml"
ansible_playbook_finalize    = "../ansible/playbooks/provision-finalize.yml"
ansible_playbook_base        = "../ansible/playbooks/provision-base.yml"
ansible_playbook_qemu        = "../ansible/playbooks/provision-qemu.yml"
ansible_playbook_virtualbox  = "../ansible/playbooks/provision-virtualbox.yml"
ansible_playbook_vmware      = "../ansible/playbooks/provision-vmware.yml"

# Virtual Machine Settings
vm_guest_os_version          = "2026.1"
vm_guest_iso_checksum_x86_64 = "3b4a3a9f5fb6532635800d3eda94414fb69a44165af6db6fa39c0bdae750c266"
vm_boot_wait                 = "10s"
vm_cpu_core                  = 4
vm_mem_size                  = 6144 # Must be at least 6144 (MB) for /tmp to be large enough
vm_root_shutdown_command     = "/sbin/shutdown -hP now"
vm_disk_size                 = 60000 # Must be at least 16000 (MB) for the Kali installation to succeed
vm_ssh_build_port            = 22
vm_ssh_timeout               = "3600s"

# QEMU Settings
qemu_accelerator    = "kvm"
qemu_disk_interface = "virtio"
qemu_net_device     = "virtio-net"
qemu_format         = "qcow2"
qemu_machine_type   = "q35"
qemu_display        = "none"
qemu_headless       = "true"

# VirtulBox Settings
vbox_graphics_controller = "vmsvga"
vbox_vram                = "256"
vbox_accelerate_3d       = "false"
vbox_firmware_type       = "efi"
vbox_clipboard_mode      = "bidirectional"
