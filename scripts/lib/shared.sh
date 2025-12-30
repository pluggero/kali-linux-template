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

# VM Management Functions (shared across scripts)
function wait_for_vm_ip() {
  local vm_name="$1"
  while true; do
    result=$(VBoxManage guestproperty get "$vm_name" "/VirtualBox/GuestInfo/Net/0/V4/IP")
    ip=$(echo "$result" | awk '{print $2}')
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$ip"
      return
    fi
    sleep 2
  done
}

function wait_for_ssh() {
  local host="$1"
  echo "Waiting for SSH to be available on $host..."
  until nc -z "$host" 22; do
    sleep 2
  done
}

function shutdown_vm_if_running() {
  local vm="$1"
  local state
  state=$(VBoxManage showvminfo "$vm" --machinereadable | grep -i "VMState=" | cut -d '"' -f 2)
  if [[ "$state" == "running" ]]; then
    # Confirm before proceeding
    echo "The VM '$vm' will be shut down for the changes to take effect."
    read -rp "Press Enter to continue..."
    echo "Shutting down VM '$vm'..."
    VBoxManage controlvm "$vm" acpipowerbutton
    until [[ "$(VBoxManage showvminfo "$vm" --machinereadable | grep -i "VMState=" | cut -d '"' -f 2)" != "running" ]]; do
      sleep 2
    done
    echo "VM '$vm' has been powered off."
  fi
}

# Packer Output Management
function get_latest_box_file() {
  local output_dir="$1"

  # Find the most recently modified directory
  local latest_dir=$(ls -dt "$output_dir"/*/ 2>/dev/null | head -1)

  if [ -z "$latest_dir" ]; then
    echo "ERROR: No output directories found in $output_dir"
    exit 1
  fi

  # Find the .box file in that directory
  local box_file=$(find "$latest_dir" -name "*.box" -type f | head -1)

  if [ -z "$box_file" ]; then
    echo "ERROR: No .box file found in $latest_dir"
    exit 1
  fi

  echo "$box_file"
}

function extract_build_info() {
  local box_file="$1"
  local box_basename=$(basename "$box_file" .box)
  local dir_basename=$(basename "$(dirname "$box_file")")

  # Try to extract from directory name first: kali-linux-VERSION-virtualbox-DATE-ARCH
  # Example: kali-linux-2025.3-virtualbox-20251021-x86_64
  if [[ $dir_basename =~ kali-linux-([0-9.]+)-virtualbox-([0-9]+)-x86_64 ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
  # Fallback: try to extract from box filename: kali-linux-VERSION-virtualbox-DATE-ARCH.box
  elif [[ $box_basename =~ kali-linux-([0-9.]+)-virtualbox-([0-9]+)-x86_64 ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
  # Fallback: extract version from box filename and date from directory
  elif [[ $box_basename =~ kali-linux-([0-9.]+) ]] && [[ $dir_basename =~ ([0-9]{8}) ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
  # Last resort: extract just version from box filename, use empty date
  elif [[ $box_basename =~ kali-linux-([0-9.]+) ]]; then
    local version="${BASH_REMATCH[1]}"
    # Try to extract date from directory name
    if [[ $dir_basename =~ ([0-9]{8}) ]]; then
      echo "$version ${BASH_REMATCH[1]}"
    else
      echo "ERROR: Cannot extract build date from directory: $dir_basename"
      exit 1
    fi
  else
    echo "ERROR: Cannot extract version and date from filename: $box_basename or directory: $dir_basename"
    exit 1
  fi
}
