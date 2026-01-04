#!/bin/bash
set -euo pipefail

function assert_dependencies() {
  local tools=("ansible-playbook" "ansible-vault" "VBoxManage" "nc" "fzf")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo "ERROR: '$tool' is not installed or in PATH."
      exit 1
    fi
  done
}

function clean_roles() {
  local roles_dir="$1"
  if [ -d "$roles_dir" ]; then
    echo "Cleaning roles in '$roles_dir'..."
    find "$roles_dir" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
    echo "Role directories cleaned."
  else
    echo "No roles found. Skipping cleanup..."
  fi
}

function install_roles() {
  local roles_dir="$1"
  for req_file in "${REQUIREMENTS_FILES[@]}"; do
    if [ -f "$req_file" ]; then
      echo "Installing roles from $req_file..."
      ansible-galaxy install -r "$req_file" --roles-path "$roles_dir" --force
    else
      echo "Warning: Requirements file $req_file not found, skipping..."
    fi
  done
}

function extract_vm_password() {
  local vault_file="$1"
  local vault_pass_file="$2"
  ansible-vault view "$vault_file" --vault-password-file "$vault_pass_file" \
    | grep user_setup_password: | cut -d '"' -f 2
}

function activate_venv() {
  local venv_path="venv/bin/activate"
  if [ -f "$venv_path" ]; then
    source "$venv_path"
  else
    echo "ERROR: Python virtual environment not found at venv/"
    echo ""
    echo "Please create and configure the virtual environment:"
    echo "  python3 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install -r requirements.txt"
    echo ""
    exit 1
  fi
}
