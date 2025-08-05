packer {
  required_version = "= 1.13.1"
  required_plugins {
    ansible = {
      version = "= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
    virtualbox = {
      version = "= 1.1.2"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}
