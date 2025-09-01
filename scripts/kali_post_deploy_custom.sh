#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"/..

source ./scripts/lib/shared.sh
source ./scripts/lib/post_deploy_core.sh

source ./scripts/config.sh
# Optional override
if [[ -n "${CONFIG_OVERRIDE:-}" && -f "$CONFIG_OVERRIDE" ]]; then
  source "$CONFIG_OVERRIDE"
fi
POST_DEPLOY_PLAYBOOK="$ANSIBLE_DIR/playbooks/post-deploy-custom.yml"

assert_dependencies

wait_for_ssh "kali.local"

clean_roles "$ROLES_DIR"
install_roles "$ROLES_DIR"

VM_PASSWORD=$(extract_vm_password "$VAULT_FILE" "$VAULT_PASS_FILE")

ANSIBLE_CONFIG="$ANSIBLE_CONFIG_FILE" \
  ansible-playbook \
  "$POST_DEPLOY_PLAYBOOK" \
  --extra-vars ansible_become_password="$VM_PASSWORD"
