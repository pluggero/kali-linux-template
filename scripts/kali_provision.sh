#!/bin/bash
cd "$(dirname "$0")"/..

source ./scripts/config.sh
source ./scripts/lib/shared.sh
source ./scripts/lib/provision_core.sh

assert_dependencies
clean_roles "$ROLES_DIR"

VM_PASSWORD=$(extract_vm_password "$VAULT_FILE" "$VAULT_PASS_FILE")
export VM_SSH_PASSWORD="$VM_PASSWORD"
trap 'unset VM_SSH_PASSWORD' EXIT

if run_packer_build; then
  LATEST_OUTPUT=$(get_latest_output_dir "$OUTPUT_DIR")
  tag_output_with_commit "$LATEST_OUTPUT"
else
  echo "Packer build failed."
  exit 1
fi
