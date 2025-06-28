packer {
  required_version = "= 1.7.0"
  required_plugins {
    ansible = {
      version = "= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    virtualbox = {
      version = "= 1.1.2"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}
