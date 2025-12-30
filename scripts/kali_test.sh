#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"/..

source ./scripts/lib/shared.sh
source ./scripts/lib/test_helpers.sh
source ./scripts/config.sh

# Optional override
if [[ -n "${CONFIG_OVERRIDE:-}" && -f "$CONFIG_OVERRIDE" ]]; then
  source "$CONFIG_OVERRIDE"
fi

# Parse command line arguments
CLEANUP_ON_SUCCESS="${1:-true}"
CLEANUP_ON_FAILURE="${2:-true}"
BOX_FILE_PATH="${3:-}"
BRIDGED_ADAPTER="${4:-}"

# Configuration
TEST_VM_CPUS="${TEST_VM_CPUS:-2}"
TEST_VM_MEMORY="${TEST_VM_MEMORY:-4096}"
SSH_USER="${SSH_USER:-kali}"
SSH_KEY="${SSH_KEY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
  echo ""
  echo "========================================"
  echo "$1"
  echo "========================================"
  echo ""
}

function print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

function print_error() {
  echo -e "${RED}✗${NC} $1"
}

function print_info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

function cleanup() {
  local exit_code=$?

  if [ -n "${TEST_VM_NAME:-}" ]; then
    local should_cleanup=false

    if [ $exit_code -eq 0 ] && [ "$CLEANUP_ON_SUCCESS" == "true" ]; then
      should_cleanup=true
    elif [ $exit_code -ne 0 ] && [ "$CLEANUP_ON_FAILURE" == "true" ]; then
      should_cleanup=true
    fi

    if [ "$should_cleanup" == "true" ]; then
      print_info "Cleaning up test VM..."
      cleanup_test_vm "$TEST_VM_NAME" true
    else
      print_info "Keeping test VM for inspection: $TEST_VM_NAME"
      if [ -n "${VM_IP:-}" ]; then
        print_info "VM IP: $VM_IP"
        print_info "SSH: ssh $SSH_USER@$VM_IP"
      fi
    fi
  fi

  exit $exit_code
}

trap cleanup EXIT INT TERM

# Main script
print_header "Kali Linux VM Test Suite"

# Check dependencies
print_info "Checking dependencies..."
if ! command -v pytest &> /dev/null; then
  print_error "pytest not found. Installing testing dependencies..."
  if [ -f "requirements-test.txt" ]; then
    pip install -r requirements-test.txt
  else
    print_error "requirements-test.txt not found. Please install: pip install pytest testinfra pytest-testinfra"
    exit 1
  fi
fi

# Find the latest box file if not specified
if [ -z "$BOX_FILE_PATH" ]; then
  print_info "Finding latest Packer output..."
  BOX_FILE=$(get_latest_box_file "$OUTPUT_DIR")
else
  BOX_FILE="$BOX_FILE_PATH"
fi

if [ ! -f "$BOX_FILE" ]; then
  print_error "Box file not found: $BOX_FILE"
  exit 1
fi

print_success "Found box file: $BOX_FILE"

# Extract version and build date for reporting
read -r VM_VERSION VM_BUILD_DATE <<< "$(extract_build_info "$BOX_FILE")"
print_info "Version: $VM_VERSION"
print_info "Build Date: $VM_BUILD_DATE"

# Generate unique VM name
TEST_VM_NAME=$(generate_unique_vm_name "kali-test")
print_info "Test VM name: $TEST_VM_NAME"

# Import box to VirtualBox
print_header "Step 1: Importing VM"
import_box_to_test_vm "$BOX_FILE" "$TEST_VM_NAME"
print_success "VM imported successfully"

# Configure VM
print_header "Step 2: Configuring VM"
configure_test_vm "$TEST_VM_NAME" "$TEST_VM_CPUS" "$TEST_VM_MEMORY" "$BRIDGED_ADAPTER"
print_success "VM configured successfully"

# Start VM and get IP
print_header "Step 3: Starting VM"
VM_IP=$(start_test_vm "$TEST_VM_NAME")
print_success "VM started with IP: $VM_IP"

# Wait for VM to be ready
print_header "Step 4: Waiting for VM to be ready"
wait_for_vm_ready "$VM_IP"
print_success "VM is ready for testing"

# Run testinfra tests
print_header "Step 5: Running Testinfra Tests"
print_info "Test directory: tests/"
print_info "SSH user: $SSH_USER"

if run_testinfra "$VM_IP" "tests" "$SSH_USER" "$SSH_KEY" ""; then
  TEST_EXIT_CODE=0
  print_header "Test Results"
  print_success "All tests passed!"
else
  TEST_EXIT_CODE=$?
  print_header "Test Results"
  print_error "Some tests failed (exit code: $TEST_EXIT_CODE)"
fi

# Report results
report_test_results $TEST_EXIT_CODE "$TEST_VM_NAME"

# Exit with test exit code
exit $TEST_EXIT_CODE
