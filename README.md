# Kali Linux Template

Reproducible, multi-platform Kali Linux VM builds using Packer and Ansible.

Layered architecture: base image (QEMU) + platform-specific configurations.

---

## Supported Platforms

| Platform             | Output Format            | Guest Utilities | Import              |
| -------------------- | ------------------------ | --------------- | ------------------- |
| VirtualBox           | VMDK + OVF + Vagrant box | Guest Additions | Import .ovf or .box |
| QEMU (alpha phase)   | qcow2                    | -               | Direct QEMU boot    |
| VMware (alpha phase) | OVA + Vagrant box        | -               | Import .ova or .box |

---

## Installation

```bash
git clone https://github.com/pluggero/kali-linux-template.git
cd kali-linux-template
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
packer init packer/versions.pkr.hcl
```

---

## Configuration

Create `ansible/inventory/group_vars/all/vault.yml`:

```yaml
ansible_user: "username"
ansible_ssh_private_key_file: "path/to/key"

# VM Configuration
vm_hostname: "custom-hostname"
vm_domain: ""
vm_username: "username"
vm_user_fullname: "Kali User"

# System Passwords
vm_grub_password: "<secure-password>"

# User Setup
user_setup_root_password: "<secure-password>"
user_setup_root_salt: "<16-char-salt-no-special-chars>"
user_setup_user_password: "<secure-password>"
user_setup_user_password_salt: "<16-char-salt-no-special-chars>"
user_setup_user_ssh_public_keys:
  - key: "ssh-ed25519 ..."
```

Encrypt with `ansible-vault encrypt ansible/inventory/group_vars/all/vault.yml` and store password in `ansible/inventory/group_vars/all/.vault_pass`.

---

## Build Targets

Available targets: `base`, `qemu`, `virtualbox`, `vmware`, `all` (default)

### Architecture

1. **base** - Builds from Kali ISO, creates QEMU qcow2 base image
   - Runs: `provision-init.yml` + `provision-base.yml`
   - Contains: System setup + common tools/desktop environment

2. **Platform targets** - Boot from base image, apply platform-specific configs
   - `qemu`: Direct QEMU usage
   - `virtualbox`: VirtualBox Guest Additions + VMDK/OVF conversion
   - `vmware`: VMware OVA packaging

### Examples

```bash
# Build everything (base + all platforms)
./scripts/kali_provision.sh

# Build only base image
./scripts/kali_provision.sh -t base

# Build specific platforms (base must exist or be included)
./scripts/kali_provision.sh -t virtualbox
./scripts/kali_provision.sh -t qemu -t virtualbox

# Build base + specific platform
./scripts/kali_provision.sh -t base -t vmware
```

---

## Output Artifacts

```
packer/outputs/kali-linux-<version>-<date>-x86_64/
├── base/
│   ├── kali-linux-*.qcow2           # Base QEMU image (reused by platforms)
│   └── kali-linux-*.qcow2.sha256
├── qemu/
│   └── kali-linux-*.qcow2           # QEMU-specific image
├── virtualbox/
│   ├── kali-linux-*.vmdk
│   └── kali-linux-*.ovf
├── vmware/
│   └── kali-linux-*.ova
└── vagrant/
    ├── kali-linux-*-virtualbox.box
    └── kali-linux-*-vmware.box
```

---

## Usage

### Build

```bash
./scripts/kali_provision.sh -t virtualbox
```

### Import

Import the generated artifacts:

- **VirtualBox**: `packer/outputs/.../virtualbox/*.ovf`
- **VMware**: `packer/outputs/.../vmware/*.ova`
- **Vagrant**: `vagrant box add packer/outputs/.../vagrant/*.box`

### Post-Deploy

Once VM is running and accessible via SSH:

```bash
./scripts/kali_post_deploy.sh        # Full setup (rename, shared folders)
./scripts/kali_post_deploy_custom.sh # Incremental customization
```

#### Disk & LVM Management

##### Extend Root Logical Volume After Disk Resize

After the virtual disk was expanded (e.g. VirtualBox, VMware, QEMU), extend the root LVM volume:

```bash
sudo growpart /dev/sda 3
sudo pvresize /dev/sda3
sudo lvextend -r -l +100%FREE /dev/vg/root
```

---

## Customization

### Modify Provisioning

Edit playbooks in `ansible/playbooks/`:

- `provision-base.yml` - Tools and desktop environment (runs on base build)
- `provision-{platform}.yml` - Platform-specific guest utilities

### Override Variables

```bash
export CONFIG_OVERRIDE=/path/to/custom/config.sh
./scripts/kali_provision.sh
```

See `scripts/config.sh` for configurable options.

### Add Tools

Add Ansible roles to `provision-base.yml` or use `tool_installer` role configuration in `ansible/vars/tool_installer.yml`.

---

## Contributing

Issues and pull requests welcome at https://github.com/pluggero/kali-linux-template

---

## License

MIT

---

## Author Information

This project is maintained by [pluggero](https://github.com/pluggero).
