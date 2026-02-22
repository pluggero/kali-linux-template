##################################################################################
# LOCALS
##################################################################################

# HTTP Settings

locals {
  kali_iso_name_x86_64     = "kali-linux-${var.vm_guest_os_version}-installer-amd64.iso"
  kali_iso_url_x86_64      = "https://kali.download/base-images/kali-${var.vm_guest_os_version}/${local.kali_iso_name_x86_64}"
  kali_iso_checksum_x86_64 = "file:https://kali.download/base-images/kali-${var.vm_guest_os_version}/SHA256SUMS"
}

local "http_directory" {
  expression = "${path.root}/http"
}

local "packer_output_path" {
  expression = "${local.qemu_output_base_dir}/qemu"
}

# Virtual Machine Settings

locals {
  vm_name                     = "kali-linux-${var.vm_guest_os_version}"
  vm_nonroot_shutdown_command = "echo '${var.vm_ssh_password}'|sudo -S shutdown -P now"
}

# https://forums.virtualbox.org/viewtopic.php?t=110897
# UEFI boot command for GRUB EFI boot loader
local "debian_boot_command_x86_64" {
  expression = [
    "e<wait>",
    "<down><down><down><end>",
    " --- ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed_file} ",
    "preseed/url/checksum=${var.preseed_checksum} ",
    "locale=en_US ",
    "keymap=us ",
    "hostname=${var.vm_hostname} ",
    "domain='' ",
    " --- ",
    "<f10>"

  ]
}

# QEMU Settings

locals {
  # Normalize packer_output_dir to absolute path
  # This handles both base layer (packer/outputs) and work layer (../../packer/outputs)
  normalized_packer_output_dir = abspath("${path.root}/${var.packer_output_dir}")

  qemu_output_name     = "${local.vm_name}-${var.BUILD_DATE}-x86_64"
  qemu_output_base_dir = "${local.normalized_packer_output_dir}/${local.qemu_output_name}"

  # Packer working directories
  base_packer_output       = "${local.qemu_output_base_dir}/base"
  qemu_packer_output       = "${local.qemu_output_base_dir}/qemu"
  virtualbox_packer_output = "${local.qemu_output_base_dir}/virtualbox-tmp"
  vmware_packer_output     = "${local.qemu_output_base_dir}/vmware-tmp"

  # Final output directories
  virtualbox_output_path = "${local.qemu_output_base_dir}/virtualbox"
  vmware_output_path     = "${local.qemu_output_base_dir}/vmware"
  vagrant_output_path    = "${local.qemu_output_base_dir}/vagrant"
}

##################################################################################
# VARIABLE DECLARATIONS
##################################################################################

# Environment Variables

variable "BUILD_DATE" {
  description = "Build date in YYYYMMDD format"
  type        = string
  default     = env("BUILD_DATE")
}

variable "HOME" {
  description = "The user's home directory"
  type        = string
  default     = env("HOME")
}

# HTTP Settings

variable "http_interface" {
  description = "The interface to use for the HTTP server"
  type        = string
  default     = ""
}

variable "preseed_file" {
  type        = string
  description = "Path to a preseed file"
}

variable "preseed_checksum" {
  type        = string
  description = "MD5SUM of the preseed file."
}

# Packer Settings

variable "packer_input_dir" {
  description = "The directory containing the input files for Packer"
  type        = string
  default     = ""
}

variable "packer_output_dir" {
  description = "The directory where Packer will output the built images"
  type        = string
  default     = ""
}

# Ansible Settings

variable "ansible_vault_password_file" {
  description = "The Ansible vault password file"
  type        = string
  default     = ""
}

variable "ansible_collections_path" {
  description = "The path to the Ansible collections"
  type        = string
  default     = ""
}

variable "ansible_roles_path" {
  description = "The path to the Ansible roles"
  type        = string
  default     = ""
}

variable "ansible_requirements_file" {
  description = "The Ansible requirements file"
  type        = string
  default     = ""
}

variable "ansible_playbook_init" {
  description = "The initial Ansible playbook"
  type        = string
  default     = ""
}

variable "ansible_playbook_finalize" {
  description = "The finalization Ansible playbook"
  type        = string
  default     = ""
}

variable "ansible_playbook_base" {
  description = "Base playbook without any guest utilities"
  type        = string
  default     = ""
}

variable "ansible_playbook_qemu" {
  description = "QEMU guest agent playbook"
  type        = string
  default     = ""
}

variable "ansible_playbook_virtualbox" {
  description = "VirtualBox-specific playbook"
  type        = string
  default     = ""
}

variable "ansible_playbook_vmware" {
  description = "VMware-specific playbook"
  type        = string
  default     = ""
}

# Virtual Machine Settings
variable "vm_guest_os_version" {
  description = "Version of guest os to install"
  type        = string
  default     = ""
}

variable "vm_boot_wait" {
  description = "Time to wait before typing the boot command"
  type        = string
  default     = ""
}

variable "vm_cpu_core" {
  description = "The number of virtual cpus"
  type        = number
}

variable "vm_mem_size" {
  description = "The amount of memory in MB"
  type        = number
}

variable "vm_root_shutdown_command" {
  description = "The command to use to gracefully shut down the VM"
  type        = string
  default     = ""
}

variable "vm_disk_size" {
  description = "The size of the disk to create in MB"
  type        = number
}

variable "vm_ssh_timeout" {
  description = "The time to wait for SSH to become available"
  type        = string
  default     = ""
}

variable "vm_ssh_port" {
  description = "The port to use for SSH"
  type        = number
}

variable "vm_hostname" {
  type        = string
  description = "The hostname of the VM"
}

variable "vm_ssh_username" {
  description = "The username to use for SSH connection"
  type        = string
  default     = ""
}

variable "vm_ssh_password" {
  description = "The password to use for SSH connection"
  type        = string
  default     = env("VM_SSH_PASSWORD")
}

variable "vm_ssh_temp_password" {
  description = "The temporary password to use for SSH connection"
  type        = string
  default     = ""
}


# QEMU Settings

variable "qemu_accelerator" {
  description = "The accelerator to use (kvm or tcg)"
  type        = string
  default     = ""
}

variable "qemu_disk_interface" {
  description = "The disk interface to use"
  type        = string
  default     = ""
}

variable "qemu_net_device" {
  description = "The network device to use"
  type        = string
  default     = ""
}

variable "qemu_format" {
  description = "The output format for QEMU (qcow2, raw, etc.)"
  type        = string
  default     = ""
}

variable "qemu_machine_type" {
  description = "The QEMU machine type"
  type        = string
  default     = ""
}

variable "qemu_display" {
  description = "The display type for QEMU"
  type        = string
  default     = ""
}

variable "qemu_headless" {
  description = "Display mode for QEMU"
  type        = string
  default     = ""
}

# VirtualBox Settings

variable "vbox_graphics_controller" {
  description = "The graphics controller for VirtualBox (vmsvga, vboxvga, vboxsvga, none)"
  type        = string
  default     = ""
}

variable "vbox_vram" {
  description = "The amount of video memory in MB for VirtualBox"
  type        = string
  default     = ""
}

variable "vbox_accelerate_3d" {
  description = "Enable 3D acceleration in VirtualBox (true/false as string)"
  type        = string
  default     = ""
}

variable "vbox_firmware_type" {
  description = "The firmware type for VirtualBox (bios/efi)"
  type        = string
  default     = ""
}

variable "vbox_clipboard_mode" {
  description = "The clipboard mode for VirtualBox (disabled/hosttoguest/guesttohost/bidirectional)"
  type        = string
  default     = ""
}
