#!/bin/bash
cd "$(dirname "$0")"/..

source ./scripts/lib/shared.sh
source ./scripts/lib/provision_core.sh

source ./scripts/config.sh
# Optional override
if [[ -n "${CONFIG_OVERRIDE:-}" && -f "$CONFIG_OVERRIDE" ]]; then
  source "$CONFIG_OVERRIDE"
fi

function usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build Kali Linux VM images using Packer.

OPTIONS:
  -t, --target <target>    Build target(s): base, qemu, virtualbox, vmware, all
                           Can be specified multiple times (e.g., -t qemu -t virtualbox)
                           Default: all
  -h, --help              Show this help message

EXAMPLES:
  $(basename "$0")                           # Build all targets (default)
  $(basename "$0") -t base                   # Build only base image
  $(basename "$0") -t virtualbox             # Build only VirtualBox image
  $(basename "$0") -t qemu -t virtualbox     # Build QEMU and VirtualBox

NOTES:
  - Platform targets (qemu, virtualbox, vmware) require base image to exist
  - When target is 'all', builds sequentially: base → qemu → virtualbox → vmware
  - Build base first, then platforms individually for debugging
EOF
}

# Parse command-line arguments
BUILD_TARGETS=()  # Array to collect multiple -t flags

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --target requires an argument"
        usage
        exit 1
      fi
      BUILD_TARGETS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Default to 'all' if no targets specified
if [[ ${#BUILD_TARGETS[@]} -eq 0 ]]; then
  BUILD_TARGETS=("all")
fi

# Verify python dependencies
assert_virtual_env
assert_python_dependencies "$PYTHON_REQUIREMENTS"

# Verify system dependencies
assert_dependencies


clean_roles "$ROLES_DIR"
install_roles "$ROLES_DIR"

# Extract vault fields with explicit error handling
echo "Extracting secrets from vault..."

VM_PASSWORD=$(extract_vm_password "$VAULT_FILE" "$VAULT_PASS_FILE") || {
  echo "FATAL: Failed to extract VM password from vault"
  exit 1
}

VM_HOSTNAME=$(extract_vm_hostname "$VAULT_FILE" "$VAULT_PASS_FILE") || {
  echo "FATAL: Failed to extract VM hostname from vault"
  exit 1
}

VM_USERNAME=$(extract_vm_username "$VAULT_FILE" "$VAULT_PASS_FILE") || {
  echo "FATAL: Failed to extract VM username from vault"
  exit 1
}

VM_USER_FULLNAME=$(extract_vm_user_fullname "$VAULT_FILE" "$VAULT_PASS_FILE") || {
  echo "FATAL: Failed to extract VM user full name from vault"
  exit 1
}

VM_GRUB_PASSWORD=$(extract_vm_grub_password "$VAULT_FILE" "$VAULT_PASS_FILE") || {
  echo "FATAL: Failed to extract GRUB password from vault"
  exit 1
}

echo "Successfully extracted vault secrets"

export VM_SSH_PASSWORD="$VM_PASSWORD"
export VM_HOSTNAME="$VM_HOSTNAME"
export VM_USERNAME="$VM_USERNAME"
export VM_USER_FULLNAME="$VM_USER_FULLNAME"
export VM_GRUB_PASSWORD="$VM_GRUB_PASSWORD"
export SSH_PORT

# Generate strong random temporary passwords for initial installation
# These will be changed by Ansible to the vault passwords
export VM_ROOT_TEMP_PASSWORD="${VM_ROOT_TEMP_PASSWORD:-$(openssl rand -base64 32)}"
export VM_USER_TEMP_PASSWORD="${VM_USER_TEMP_PASSWORD:-$(openssl rand -base64 32)}"

trap 'unset VM_SSH_PASSWORD VM_HOSTNAME VM_USERNAME VM_USER_FULLNAME VM_GRUB_PASSWORD VM_ROOT_TEMP_PASSWORD VM_USER_TEMP_PASSWORD' EXIT

if run_packer_build "${PACKER_VARS_FILE:-}" "${BUILD_TARGETS[@]}"; then
  LATEST_OUTPUT=$(get_latest_output_dir "$OUTPUT_DIR")
  tag_output_with_commit "$LATEST_OUTPUT"
else
  echo "Packer build failed."
  exit 1
fi
