terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Local backend for development
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "local" {}
provider "null" {}

# Data source to find the latest box file
locals {
  packer_output_dir = "../../../packer/outputs"

  # Find the latest Kali box file
  latest_box_file = var.box_file != "" ? var.box_file : "${local.packer_output_dir}/${var.vm_version}/kali-linux-${var.vm_version}-virtualbox-${var.vm_build_date}-x86_64.box"
}

module "kali_vm" {
  source = "../../modules/virtualbox-vm"

  vm_name             = var.vm_name
  box_file            = local.latest_box_file
  cpus                = var.cpus
  memory              = var.memory
  bridged_adapter     = var.bridged_adapter
  vram                = var.vram
  graphics_controller = var.graphics_controller
  clipboard_mode      = var.clipboard_mode
  env                 = "dev"

  # Post-deployment configuration
  run_post_deploy     = var.run_post_deploy
  post_deploy_script  = var.post_deploy_script
}
