#!/bin/bash

# === Directories ===
ANSIBLE_DIR="ansible"
PACKER_DIR="packer"
ROLES_DIR="$ANSIBLE_DIR/roles"
OUTPUT_DIR="$PACKER_DIR/outputs"

# === Vault ===
VAULT_FILE="$ANSIBLE_DIR/inventory/group_vars/all/vault.yml"
VAULT_PASS_FILE="$ANSIBLE_DIR/inventory/group_vars/all/.vault_pass"

# === Ansible ===
ANSIBLE_CONFIG_FILE="$ANSIBLE_DIR/ansible.cfg"
POST_DEPLOY_PLAYBOOK="$ANSIBLE_DIR/playbooks/post-deploy.yml"

# === Requirements Files (multiple supported) ===
# Define requirements files as an array
REQUIREMENTS_FILES=("$ANSIBLE_DIR/requirements.yml")

# === Shared Folder Configuration (multiple supported) ===
# Define shared folder parameters as parallel arrays

SHARED_FOLDER_NAMES=("shared")
SHARED_FOLDER_MOUNT_POINTS=("/mnt/shared")
SHARED_FOLDER_SEARCH_ROOTS=("$HOME")
SHARED_FOLDER_SEARCH_DEPTHS=(3)
