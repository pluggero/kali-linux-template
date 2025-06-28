packer {
  required_version = "= 1.13.1"
  required_plugins {
    ansible = {
      version = "= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    virtualbox = {
      version = "= 1.1.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}
