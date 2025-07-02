#!/bin/bash

# === Vault ===
VAULT_FILE="ansible/inventory/group_vars/all/vault.yml"
VAULT_PASS_FILE="ansible/inventory/group_vars/all/.vault_pass"

# === Directories ===
ROLES_DIR="ansible/roles"
PACKER_DIR="packer"
ANSIBLE_DIR="ansible"
OUTPUT_DIR="$PACKER_DIR/outputs"

# === Ansible ===
ANSIBLE_CONFIG_FILE="$ANSIBLE_DIR/ansible.cfg"
POST_DEPLOY_PLAYBOOK="$ANSIBLE_DIR/playbooks/post-deploy.yml"

# === Shared Folder Configuration (multiple supported) ===
# Define shared folder parameters as parallel arrays

SHARED_FOLDER_NAMES=("shared")
SHARED_FOLDER_MOUNT_POINTS=("/mnt/shared")
SHARED_FOLDER_SEARCH_ROOTS=("$HOME")
SHARED_FOLDER_SEARCH_DEPTHS=(3)
