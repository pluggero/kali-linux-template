#!/bin/bash

set -euo pipefail

# Change to the ansible directory
cd "$(dirname "$0")"/../ansible

ROLES_DIR="roles"

# Delete all subdirectories (roles) inside the roles directory
if [ -d "$ROLES_DIR" ]; then
  echo "Cleaning all role directories in '$ROLES_DIR'..."
  find "$ROLES_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
  echo "Role directories cleaned."
else
  echo "No roles directory found. Skipping cleanup."
fi

# Install roles
echo "Installing roles from requirements.yml..."
ansible-galaxy install -r requirements.yml --force

# Run the playbook
echo "Running post-deploy-base playbook..."
ansible-playbook -i inventory/hosts playbooks/post-deploy-base.yml --ask-become-pass

