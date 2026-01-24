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
