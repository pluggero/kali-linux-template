##################################################################################
# LOCALS
##################################################################################

# HTTP Settings

locals {
  kali_iso_name_x86_64     = "kali-linux-${var.vm_guest_os_version}-installer-amd64.iso"
  kali_iso_url_x86_64      = "https://old.kali.org/kali-images/kali-${var.vm_guest_os_version}/${local.kali_iso_name_x86_64}"
  kali_iso_checksum_x86_64 = "sha256:${var.vm_guest_iso_checksum_x86_64}"
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

# Boot command
locals {
  debian_boot_clear_existing_kernel_args = join("", [for _ in range(112) : "<bs>"])
  
  # Hostname and domain have to be set in boot command because of network-based preseeding
  # See https://wiki.debian.org/DebianInstaller/Preseed#Loading_the_preseeding_file_from_a_webserver
  debian_boot_kernel_args = format(
    " auto=true priority=critical netcfg/get_hostname=%s netcfg/get_domain=%s preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed_file} ---",
    var.vm_hostname,
    var.vm_domain,
  )

  debian_boot_command_x86_64 = [
    "e<wait>",
    "<down><down><down><end><wait>",
    local.debian_boot_clear_existing_kernel_args,
    local.debian_boot_kernel_args,
    "<f10>",
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

variable "vm_guest_iso_checksum_x86_64" {
  description = "Checksum of the iso installer"
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

variable "vm_ssh_build_port" {
  description = "The temporary SSH port used during Packer build"
  type        = number
}

variable "vm_hostname" {
  type        = string
  description = "The hostname of the VM"
  default     = env("VM_HOSTNAME")

  validation {
    condition     = length(var.vm_hostname) > 0
    error_message = "The vm_hostname variable cannot be empty. Ensure VM_HOSTNAME environment variable is set."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$", var.vm_hostname))
    error_message = "The vm_hostname must be a valid RFC 1123 hostname (alphanumeric and hyphens, 1-63 chars)."
  }
}

variable "vm_domain" {
  type        = string
  description = "The domain name of the VM"
  default     = env("VM_DOMAIN")
}

variable "vm_username" {
  type        = string
  description = "The username for the VM"
  default     = env("VM_USERNAME")

  validation {
    condition     = length(var.vm_username) > 0
    error_message = "The vm_username variable cannot be empty. Ensure VM_USERNAME environment variable is set."
  }
}

variable "vm_user_fullname" {
  type        = string
  description = "The full name for the VM user"
  default     = env("VM_USER_FULLNAME")

  validation {
    condition     = length(var.vm_user_fullname) > 0
    error_message = "The vm_user_fullname variable cannot be empty. Ensure VM_USER_FULLNAME environment variable is set."
  }
}

variable "vm_ssh_username" {
  description = "The username to use for SSH connection"
  type        = string
  default     = env("VM_USERNAME")
}

variable "vm_ssh_password" {
  description = "The password to use for SSH connection"
  type        = string
  default     = env("VM_SSH_PASSWORD")
}

variable "vm_ssh_temp_password" {
  description = "The temporary password to use for SSH connection during base build"
  type        = string
  default     = env("VM_USER_TEMP_PASSWORD")
}

variable "vm_grub_password" {
  description = "GRUB bootloader password"
  type        = string
  sensitive   = true
  default     = env("VM_GRUB_PASSWORD")
}

variable "vm_root_temp_password" {
  description = "Temporary root password for initial build"
  type        = string
  sensitive   = true
  default     = env("VM_ROOT_TEMP_PASSWORD")
}

variable "vm_user_temp_password" {
  description = "Temporary user password for initial build"
  type        = string
  sensitive   = true
  default     = env("VM_USER_TEMP_PASSWORD")
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
