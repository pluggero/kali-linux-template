#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"/..

source ./scripts/config.sh
source ./scripts/lib/shared.sh
source ./scripts/lib/post_deploy_core.sh

assert_dependencies

current_vm=$(select_vm)
[[ -z "$current_vm" ]] && echo "No VM selected." && exit 1

shutdown_vm_if_running "$current_vm"

# Rename
new_vm=$(ask_rename_vm "$current_vm")

# Select and add shared folder
selected_folder=$(find "$HOME" -mindepth 1 -maxdepth 3 -type d | fzf --prompt="Select shared folder: ")
[[ -z "$selected_folder" ]] && echo "No folder selected." && exit 1

add_shared_folder "$new_vm" "$SHARED_FOLDER_NAME" "$selected_folder" "$SHARED_FOLDER_MOUNT_POINT"

VBoxManage startvm "$new_vm" --type headless
echo "Waiting for VM '$new_vm' to acquire an IP address..."
ip_address=$(wait_for_vm_ip "$new_vm")

echo "Add to /etc/hosts:"
echo "$ip_address kali.local"
read -rp "Press Enter to continue..."

wait_for_ssh "kali.local"

clean_roles "$ROLES_DIR"
ansible-galaxy install -r "$ANSIBLE_DIR/requirements.yml" --roles-path "$ROLES_DIR" --force

VM_PASSWORD=$(extract_vm_password "$VAULT_FILE" "$VAULT_PASS_FILE")

ANSIBLE_CONFIG="$ANSIBLE_CONFIG_FILE" \
  ansible-playbook \
  "$POST_DEPLOY_PLAYBOOK" \
  --extra-vars ansible_become_password="$VM_PASSWORD"
