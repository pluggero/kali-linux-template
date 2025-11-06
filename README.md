# Kali Linux Template

A reproducible, automated build pipeline for creating custom Kali Linux virtual machines using **Packer** and **Ansible**.

Currently supported platforms:

- VirtualBox

---

## Getting started

### Installation

1. Clone the repository:

```
git clone https://github.com/pluggero/kali-linux-template.git
cd kali-linux-template
```

2. Install virtual environment:

```
python3 -m venv venv
source venv/bin/activate
```

3. Install dependencies:

```
pip install -r requirements.txt
```

4. Install Packer plugins:

```
packer init packer/versions.pkr.hcl
```

### Configuration

1. Create `vault.yml` file in `ansible/inventory/group_vars/all` directory:

```
ansible_user: "<YOUR_USERNAMR>"
ansible_ssh_private_key_file: "<PATH_TO_PRIVATE_KEY>"
user_setup_password: "<USER_PASSWORD>"
user_setup_password_salt: "<PASSWORD_SALT>"
user_setup_ssh_public_keys:
    - key: "<YOUR_SSH_PUBLIC_KEY>"
```

- **NOTE**: You can use the following command to generate a random password salt (it must be 16 characters long and should not include special characters):

```
openssl rand -base64 32 | cut -c 16
```

2. Create `.vault_pass` file containing the vault password in `ansible/inventory/group_vars/all` directory:

```
echo "<YOUR_VAULT_PASSWORD>" > ansible/inventory/group_vars/all/.vault_pass
chmod 600 ansible/inventory/group_vars/all/.vault_pass
```

- **NOTE**: Your vault and its password are **never committed** to version control (see `.gitignore`).

---

## Usage

### Build the Virtual Machine

This command runs Packer and Ansible to build a VirtualBox VM image:

```
./scripts/kali_provision.sh
```

- **NOTE**: The output will be saved in the `packer/outputs` directory.

### Import the VM

Import the resulting `.ovf` or `.box` file into **VirtualBox** manually or via **Terraform** (TBD).

### Post-Deployment Configuration

Once the VM is running and accessible via SSH:

```
./scripts/kali_post_deploy.sh
```

This applies additional post-configuration (e.g., user setup, shared folders, extra tools).

---

## Contributing

Contributions are welcome!

---

## License

MIT

---

## Author Information

This project is maintained by [pluggero](https://github.com/pluggero).
