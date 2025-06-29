##################################################################################
# LOCALS
##################################################################################

# HTTP Settings

locals {
  kali_iso_name_x86_64 = "kali-linux-${var.vm_guest_os_version}-installer-amd64.iso"
  kali_iso_url_x86_64 = "https://old.kali.org/kali-images/kali-${var.vm_guest_os_version}/${local.kali_iso_name_x86_64}"
  kali_iso_checksum_x86_64 = "file:https://old.kali.org/kali-images/kali-${var.vm_guest_os_version}/SHA256SUMS"
}

local "http_directory" {
  expression = "${path.root}/http"
}

# Virtual Machine Settings

locals { 
  vm_name = "kali-linux-${var.vm_guest_os_version}"
  vm_nonroot_shutdown_command = "echo '${var.vm_ssh_password}'|sudo -S shutdown -P now"
} 

# https://forums.virtualbox.org/viewtopic.php?t=110897
# for uefi boot to work: "vga=788 noprompt fb=false quiet --<enter>"
local "debian_boot_command_x86_64" {
  expression = [
    "<wait><wait><wait><esc><wait><wait><wait>",
    "/install.amd/vmlinuz ",
    "initrd=/install.amd/initrd.gz ",
    "auto=true ",
    "hostname=kali ",
    "domain='' ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "interface=auto ",
    "vga=788 noprompt quiet --<enter>"
  ]
}

# VirtualBox Settings

locals {
    vbox_output_name = "${local.vm_name}-virtualbox-${formatdate("YYYYMMDD", timestamp())}-x86_64"
}

##################################################################################
# VARIABLE DECLARATIONS
##################################################################################

# Environment Variables

variable "HOME" {
  description = "The user's home directory"
  type = string
  default = env("HOME")
}

# HTTP Settings

variable "http_interface" {
  description = "The interface to use for the HTTP server"
  type = string
  default = ""
}

# Virtual Machine Settings
variable "vm_guest_os_version" {
  description = "Version of guest os to install"
  type = string
  default = ""
}

variable "vm_boot_wait" {
  description = "Time to wait before typing the boot command"
  type = string
  default = ""
}

variable "vm_cpu_core" {
  description = "The number of virtual cpus"
  type = number
}

variable "vm_mem_size" {
  description = "The amount of memory in MB"
  type = number
}

variable "vm_root_shutdown_command" {
  description = "The command to use to gracefully shut down the VM"
  type = string
  default = ""
}

# This has to be at least 16000 MB for the Kali installation to succeed
variable "vm_disk_size" {
  description = "The size of the disk to create in MB"
  type = number
}

variable "vm_ssh_timeout" {
  description = "The time to wait for SSH to become available"
  type = string
  default = ""
}

variable "vm_ssh_port" {
  description = "The port to use for SSH"
  type = number
}

variable "vm_ssh_username" {
  description = "The username to use for SSH connection"
  type = string
  default = ""
}

variable "vm_ssh_password" {
  description = "The password to use for SSH connection"
  type = string
  default =  env("VM_SSH_PASSWORD")
}

variable "vm_ssh_temp_password" {
  description = "The temporary password to use for SSH connection"
  type = string
  default = "" 
}


# VirtualBox Settings

variable "vbox_vm_headless" {
  description = "Run the VM in headless mode"
  type = bool
  default = true
}

variable "vbox_guest_additions" {
  description = "Install the VirtualBox Guest Additions"
  type = string
  default = ""
}

variable "vbox_post_cpu_core" {
  description = "The number of virtual cpus after the VM has been created"
  type = number
}

variable "vbox_post_mem_size" {
  description = "The amount of memory in MB after the VM has been created"
  type = number
}

variable "vbox_post_bridged_adapter" {
  description = "The bridged network adapter to use after the VM has been created"
  type = string
  default = ""
}

variable "vbox_post_graphics" {
  description = "The graphics controller to use after the VM has been created"
  type = string
  default = ""
}

variable "vbox_post_vram" {
  description = "The amount of video memory to use after the VM has been created"
  type = number
}

variable "vbox_post_accelerate_3d" {
  description = "Enable 3D acceleration after the VM has been created"
  type = string
  default = ""
}

variable "vbox_post_clipboard_mode" {
  description = "The clipboard mode to use after the VM has been created"
  type = string
  default = ""
}

variable "vbox_output_format" {
  description = "The format of the output"
  type = string
  default = ""
}
