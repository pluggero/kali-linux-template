packer {
  required_version = "= 1.15.1"
  required_plugins {
    ansible = {
      version = "= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
    qemu = {
      version = "~> 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}
