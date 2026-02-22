#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"/..

source ./scripts/lib/shared.sh
source ./scripts/lib/post_deploy_core.sh

source ./scripts/config.sh
# Optional override
if [[ -n "${CONFIG_OVERRIDE:-}" && -f "$CONFIG_OVERRIDE" ]]; then
  source "$CONFIG_OVERRIDE"
fi

# Verify python dependencies
assert_virtual_env
assert_python_dependencies "$PYTHON_REQUIREMENTS"

# Verify system dependencies
assert_dependencies

current_vm=$(select_vm)
[[ -z "$current_vm" ]] && echo "No VM selected." && exit 1

shutdown_vm_if_running "$current_vm"

# Rename
new_vm=$(ask_rename_vm "$current_vm")

setup_all_shared_folders

VBoxManage startvm "$new_vm" --type headless
echo "Waiting for VM '$new_vm' to acquire an IP address..."
ip_address=$(wait_for_vm_ip "$new_vm")

echo "Add to /etc/hosts:"
echo "$ip_address kali.local"
read -rp "Press Enter to continue..."

wait_for_ssh "kali.local"

clean_roles "$ROLES_DIR"
install_roles "$ROLES_DIR"

VM_PASSWORD=$(extract_vm_password "$VAULT_FILE" "$VAULT_PASS_FILE")

export SSH_PORT

ANSIBLE_CONFIG="$ANSIBLE_CONFIG_FILE" \
  ansible-playbook \
  "$POST_DEPLOY_PLAYBOOK" \
  --extra-vars ansible_become_password="$VM_PASSWORD"
