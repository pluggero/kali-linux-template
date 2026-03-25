#!/bin/bash
set -euo pipefail

function assert_virtual_env() {
  # Check if virtual environment is active
  if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    echo "ERROR: Python virtual environment is not active."
    exit 1
  fi

  # Verify the virtual environment directory exists
  if [[ ! -d "$VIRTUAL_ENV" ]]; then
    echo "ERROR: Virtual environment directory does not exist: $VIRTUAL_ENV"
    exit 1
  fi

  # Verify python is accessible
  if ! command -v python &> /dev/null; then
    echo "ERROR: Python interpreter not found in virtual environment."
    exit 1
  fi
}

# Validates Python dependencies from requirements.txt
# Uses importlib.metadata (Python 3.8+ standard library)
# Supports only pinned versions (package==version format)
function assert_python_dependencies() {
  local requirements_file="${1:-requirements.txt}"

  # Verify Python version supports importlib.metadata (3.8+)
  if ! python -c "import importlib.metadata" &> /dev/null; then
    local python_version
    python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "unknown")
    echo "ERROR: Python version $python_version does not support importlib.metadata (requires Python 3.8+)."
    echo "       Please upgrade your Python environment."
    exit 1
  fi

  # Check if requirements.txt exists
  if [[ ! -f "$requirements_file" ]]; then
    echo "ERROR: Requirements file not found: $requirements_file"
    exit 1
  fi

  # Parse requirements.txt and validate each package
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract package name and version
    local package_spec="$line"
    local package_name
    local required_version

    if [[ "$package_spec" =~ ^([a-zA-Z0-9_-]+)==([0-9.]+)$ ]]; then
      package_name="${BASH_REMATCH[1]}"
      required_version="${BASH_REMATCH[2]}"
    else
      continue
    fi

    # Check if package is installed using importlib.metadata
    if ! python -c "import importlib.metadata; importlib.metadata.version('$package_name')" &> /dev/null; then
      echo "ERROR: Required Python package '$package_name' is not installed."
      exit 1
    fi

    # Check version if specified
    if [[ -n "$required_version" ]]; then
      local installed_version
      installed_version=$(python -c "import importlib.metadata; print(importlib.metadata.version('$package_name'))" 2>/dev/null)

      if [[ "$installed_version" != "$required_version" ]]; then
        echo "ERROR: Python package '$package_name' version mismatch (required: $required_version, installed: $installed_version)."
        exit 1
      fi
    fi
  done < "$requirements_file"
}

function assert_dependencies() {
  local tools=("ansible-playbook" "ansible-vault" "VBoxManage" "nc" "fzf")
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      echo "ERROR: '$tool' is not installed or in PATH."
      exit 1
    fi
  done
}

# Checks that sufficient disk space is available on the filesystem containing <path>.
# Walks up to the nearest existing ancestor if <path> does not yet exist.
# Usage: assert_disk_space <path> <min_gb>
function assert_disk_space() {
  local check_path="$1"
  local min_gb="$2"

  # Walk up to the nearest existing ancestor
  local resolve_path="$check_path"
  while [[ ! -d "$resolve_path" ]]; do
    resolve_path="$(dirname "$resolve_path")"
    if [[ "$resolve_path" == "/" ]]; then
      echo "ERROR: Cannot resolve filesystem for path: $check_path"
      exit 1
    fi
  done

  local available_gb
  available_gb=$(df -P "$resolve_path" | awk 'NR==2 {print int($4 / 1048576)}')

  if [[ -z "$available_gb" ]]; then
    echo "ERROR: Failed to determine available disk space for: $resolve_path"
    exit 1
  fi

  if (( available_gb < min_gb )); then
    echo "ERROR: Insufficient disk space."
    echo "       Required : ${min_gb}G"
    echo "       Available: ${available_gb}G"
    exit 1
  fi
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

function extract_vault_field() {
  local vault_file="$1"
  local vault_pass_file="$2"
  local field_name="$3"

  # Get the directory where this script is located
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Path to Python extraction script
  local python_script="${script_dir}/extract_vault_field.py"

  # Validate Python script exists
  if [[ ! -f "$python_script" ]]; then
    echo "ERROR: Python extraction script not found: ${python_script}" >&2
    return 1
  fi

  # Call Python script for robust YAML parsing
  local value
  value=$(python "$python_script" "$vault_file" "$vault_pass_file" "$field_name" 2>&1)
  local exit_code=$?

  # Check if extraction failed
  if [[ $exit_code -ne 0 ]]; then
    # Error message already printed by Python script to stderr
    return 1
  fi

  # Validate value is not empty
  if [[ -z "$value" ]]; then
    echo "ERROR: Extracted value for '${field_name}' is empty" >&2
    return 1
  fi

  echo "$value"
}

function extract_vm_password() {
  extract_vault_field "$1" "$2" "user_setup_user_password"
}

function extract_vm_hostname() {
  extract_vault_field "$1" "$2" "vm_hostname"
}

function extract_vm_domain() {
  extract_vault_field "$1" "$2" "vm_domain"
}

function extract_vm_username() {
  extract_vault_field "$1" "$2" "vm_username"
}

function extract_vm_user_fullname() {
  extract_vault_field "$1" "$2" "vm_user_fullname"
}

function extract_vm_grub_password() {
  extract_vault_field "$1" "$2" "vm_grub_password"
}

function extract_vm_root_password() {
  extract_vault_field "$1" "$2" "user_setup_root_password"
}

function extract_vm_root_password_salt() {
  extract_vault_field "$1" "$2" "user_setup_root_salt"
}
