#!/bin/bash
# Change to the repository root directory
cd "$(dirname "$0")"/..

# Delete all subdirectories (roles) inside the ansible roles directory
ROLES_DIR="ansible/roles"
if [ -d "$ROLES_DIR" ]; then
  echo "Cleaning all role directories in '$ROLES_DIR'..."
  find "$ROLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
  echo "Role directories cleaned."
else
  echo "No roles directory found. Skipping cleanup."
fi

# Load VM password from ansible vault
VAULT_FILE="ansible/inventory/group_vars/all/vault.yml"
VAULT_PASS_FILE="ansible/inventory/group_vars/all/.vault_pass"

echo "Extracting VM SSH password from Ansible vault..."
VM_PASSWORD=$(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" | \
  grep user_setup_password: | cut -d '"' -f 2)

# Export password as env var
export VM_SSH_PASSWORD="$VM_PASSWORD"
echo "Exported VM_SSH_PASSWORD."

# Ensure variable is unset on script exit
trap 'unset VM_SSH_PASSWORD' EXIT

# Run the Packer build and capture the exit code
packer build -force -on-error=ask packer/
PACKER_EXIT_CODE=$?

if [ "$PACKER_EXIT_CODE" -eq 0 ]; then
  # Get the current Git commit hash
  COMMIT_HASH=$(git rev-parse HEAD)

  # Find the most recently modified directory in outputs/
  LATEST_OUTPUT=$(find packer/outputs/ -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" | sort -nr | head -n 1 | cut -d' ' -f2-)

  if [ -n "$LATEST_OUTPUT" ]; then
    # Create a version.txt file in the created output directory
    echo "$COMMIT_HASH" > "$LATEST_OUTPUT/version.txt"
    echo "Written commit $COMMIT_HASH to $LATEST_OUTPUT/version.txt"
  else
    echo "No output directory found."
    exit 1
  fi
fi
