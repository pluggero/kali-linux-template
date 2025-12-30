#!/bin/bash
cd "$(dirname "$0")"/..

source ./scripts/lib/shared.sh
source ./scripts/lib/deploy.sh
source ./scripts/config.sh

# Optional override
if [[ -n "${CONFIG_OVERRIDE:-}" && -f "$CONFIG_OVERRIDE" ]]; then
  source "$CONFIG_OVERRIDE"
fi

ENVIRONMENT="${1:-dev}"
ACTION="${2:-apply}"
RUN_POST_DEPLOY="${3:-false}"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
  echo "ERROR: Invalid environment '$ENVIRONMENT'. Must be 'dev' or 'prod'."
  echo "Usage: $0 <dev|prod> [apply|plan|destroy] [run_post_deploy]"
  echo ""
  echo "Examples:"
  echo "  $0 dev apply              # Deploy without post-configuration"
  echo "  $0 dev apply true         # Deploy with automatic post-configuration"
  echo "  $0 dev destroy            # Destroy the VM"
  exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(apply|plan|destroy)$ ]]; then
  echo "ERROR: Invalid action '$ACTION'. Must be 'apply', 'plan', or 'destroy'."
  echo "Usage: $0 <dev|prod> [apply|plan|destroy] [run_post_deploy]"
  exit 1
fi

TERRAFORM_ENV_DIR="terraform/environments/$ENVIRONMENT"

# Check if Terraform directory exists
if [ ! -d "$TERRAFORM_ENV_DIR" ]; then
  echo "ERROR: Terraform environment directory not found: $TERRAFORM_ENV_DIR"
  exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
  echo "ERROR: 'terraform' is not installed or in PATH."
  exit 1
fi

# Find the latest box file
echo "Finding latest Packer output..."
BOX_FILE=$(get_latest_box_file "$OUTPUT_DIR")
echo "Found: $BOX_FILE"

# Extract version and build date
read -r VM_VERSION VM_BUILD_DATE <<< "$(extract_build_info "$BOX_FILE")"
echo "Version: $VM_VERSION"
echo "Build Date: $VM_BUILD_DATE"

# Initialize Terraform if needed
if [ ! -d "$TERRAFORM_ENV_DIR/.terraform" ]; then
  terraform_init "$TERRAFORM_ENV_DIR"
fi

# Build Terraform arguments
TERRAFORM_ARGS=(
  -var "box_file=$(realpath "$BOX_FILE")"
  -var "vm_version=$VM_VERSION"
  -var "vm_build_date=$VM_BUILD_DATE"
)

# Add post-deploy flag if requested
if [[ "$RUN_POST_DEPLOY" == "true" ]]; then
  TERRAFORM_ARGS+=(-var "run_post_deploy=true")
fi

# Execute the requested action
case "$ACTION" in
  plan)
    terraform_plan "$TERRAFORM_ENV_DIR" "${TERRAFORM_ARGS[@]}"
    ;;
  apply)
    terraform_apply "$TERRAFORM_ENV_DIR" "${TERRAFORM_ARGS[@]}" -auto-approve

    # Get VM name from terraform output
    VM_NAME=$(cd "$TERRAFORM_ENV_DIR" && terraform output -raw vm_name 2>/dev/null || echo "")

    echo ""
    echo "==============================================="
    echo "VM deployed successfully!"
    echo "==============================================="
    if [ -n "$VM_NAME" ]; then
      echo "VM Name: $VM_NAME"
      echo ""
      echo "Get VM IP address:"
      echo "  VBoxManage guestproperty get \"$VM_NAME\" /VirtualBox/GuestInfo/Net/0/V4/IP"
      echo ""
      echo "To access via SSH (after getting IP):"
      echo "  ssh kali@<VM_IP>"
    fi
    echo ""
    if [[ "$RUN_POST_DEPLOY" != "true" ]]; then
      echo "To run post-deployment configuration manually:"
      echo "  ./scripts/kali_post_deploy.sh"
      echo ""
      echo "Or re-deploy with automatic post-configuration:"
      echo "  $0 $ENVIRONMENT apply true"
    fi
    echo "==============================================="
    ;;
  destroy)
    terraform_destroy "$TERRAFORM_ENV_DIR" "${TERRAFORM_ARGS[@]}" -auto-approve
    echo "VM destroyed successfully!"
    ;;
esac
