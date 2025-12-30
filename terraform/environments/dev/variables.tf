variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "kali-linux-dev"
}

variable "vm_version" {
  description = "Kali Linux version (e.g., 2025.3)"
  type        = string
  default     = "2025.3"
}

variable "vm_build_date" {
  description = "Build date in YYYYMMDD format"
  type        = string
  default     = ""
}

variable "box_file" {
  description = "Path to the Vagrant box file (leave empty to auto-detect latest)"
  type        = string
  default     = ""
}

variable "cpus" {
  description = "Number of CPU cores"
  type        = number
  default     = 3
}

variable "memory" {
  description = "Memory size in MB"
  type        = number
  default     = 8192
}

variable "bridged_adapter" {
  description = "Network interface to bridge to"
  type        = string
  default     = "pentap0"
}

variable "vram" {
  description = "Video memory in MB"
  type        = number
  default     = 256
}

variable "graphics_controller" {
  description = "Graphics controller type"
  type        = string
  default     = "vmsvga"
}

variable "clipboard_mode" {
  description = "Clipboard sharing mode"
  type        = string
  default     = "bidirectional"
}

variable "run_post_deploy" {
  description = "Run post-deployment Ansible configuration automatically"
  type        = bool
  default     = false
}

variable "post_deploy_script" {
  description = "Path to post-deployment script (relative to project root)"
  type        = string
  default     = "../../../scripts/kali_post_deploy.sh"
}
