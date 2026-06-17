packer {
  required_version = "= 1.15.4"
  required_plugins {
    ansible = {
      version = "= 1.1.5"
      source  = "github.com/hashicorp/ansible"
    }
    qemu = {
      version = "~> 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}
