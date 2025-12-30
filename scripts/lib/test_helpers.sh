#!/bin/bash
set -euo pipefail

# Import shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

# VM Import and Management for Testing
function import_box_to_test_vm() {
  local box_file="$1"
  local test_vm_name="$2"

  echo "Importing box file to test VM: $test_vm_name"

  # Extract the OVF from the box file (box is a tar archive)
  local tmp_dir=$(mktemp -d)
  trap "rm -rf '$tmp_dir'" RETURN

  tar -xzf "$box_file" -C "$tmp_dir"

  # Find the OVF file
  local ovf_file=$(find "$tmp_dir" -name "*.ovf" -type f | head -1)

  if [ -z "$ovf_file" ]; then
    echo "ERROR: No OVF file found in box archive"
    return 1
  fi

  # Import the OVF
  VBoxManage import "$ovf_file" --vsys 0 --vmname "$test_vm_name"

  echo "VM '$test_vm_name' imported successfully"
}

function configure_test_vm() {
  local vm_name="$1"
  local cpus="${2:-2}"
  local memory="${3:-4096}"
  local bridged_adapter="${4:-}"

  echo "Configuring test VM: $vm_name"

  # Configure hardware
  VBoxManage modifyvm "$vm_name" --cpus "$cpus"
  VBoxManage modifyvm "$vm_name" --memory "$memory"
  VBoxManage modifyvm "$vm_name" --vram 128

  # Configure network
  if [ -n "$bridged_adapter" ]; then
    VBoxManage modifyvm "$vm_name" --nic1 bridged --bridgeadapter1 "$bridged_adapter"
  else
    # Use NAT if no adapter specified
    VBoxManage modifyvm "$vm_name" --nic1 nat
  fi

  echo "VM '$vm_name' configured successfully"
}

function start_test_vm() {
  local vm_name="$1"

  echo "Starting test VM: $vm_name"
  VBoxManage startvm "$vm_name" --type headless

  echo "Waiting for VM to acquire IP address..."
  local vm_ip=$(wait_for_vm_ip "$vm_name")

  echo "VM started with IP: $vm_ip"
  echo "$vm_ip"
}

function cleanup_test_vm() {
  local vm_name="$1"
  local force="${2:-false}"

  echo "Cleaning up test VM: $vm_name"

  # Check if VM exists
  if ! VBoxManage list vms | grep -q "\"$vm_name\""; then
    echo "VM '$vm_name' does not exist, skipping cleanup"
    return 0
  fi

  # Get VM state
  local state=$(VBoxManage showvminfo "$vm_name" --machinereadable 2>/dev/null | grep -i "VMState=" | cut -d '"' -f 2 || echo "unknown")

  # Power off if running
  if [[ "$state" == "running" ]]; then
    echo "Powering off VM '$vm_name'..."
    VBoxManage controlvm "$vm_name" poweroff || true
    sleep 3
  fi

  # Unregister and delete
  echo "Removing VM '$vm_name'..."
  VBoxManage unregistervm "$vm_name" --delete || true

  echo "VM '$vm_name' cleaned up successfully"
}

function get_vm_ssh_config() {
  local vm_ip="$1"
  local ssh_user="${2:-kali}"
  local ssh_key="${3:-}"

  local ssh_config="ssh://${ssh_user}@${vm_ip}"

  if [ -n "$ssh_key" ]; then
    echo "$ssh_config?ssh_identity_file=$ssh_key"
  else
    echo "$ssh_config"
  fi
}

function run_testinfra() {
  local vm_ip="$1"
  local test_dir="${2:-tests}"
  local ssh_user="${3:-kali}"
  local ssh_key="${4:-}"
  local extra_args="${5:-}"

  echo "Running testinfra tests..."
  echo "VM IP: $vm_ip"
  echo "Test directory: $test_dir"

  # Export environment variables for pytest
  export KALI_VM_IP="$vm_ip"
  export KALI_SSH_USER="$ssh_user"

  if [ -n "$ssh_key" ]; then
    export KALI_SSH_KEY="$ssh_key"
  fi

  # Build pytest arguments
  local pytest_args=(
    "$test_dir"
    "-v"
    "--tb=short"
    "--color=yes"
  )

  # Add SSH connection string
  local ssh_config=$(get_vm_ssh_config "$vm_ip" "$ssh_user" "$ssh_key")
  pytest_args+=("--hosts=$ssh_config")

  # Add extra arguments if provided
  if [ -n "$extra_args" ]; then
    pytest_args+=($extra_args)
  fi

  # Check if pytest is available
  if ! command -v pytest &> /dev/null; then
    echo "ERROR: pytest is not installed. Please install testing dependencies:"
    echo "  pip install -r requirements-test.txt"
    return 1
  fi

  # Run pytest
  pytest "${pytest_args[@]}"
  local exit_code=$?

  return $exit_code
}

function report_test_results() {
  local exit_code="$1"
  local vm_name="$2"

  echo ""
  echo "========================================"
  echo "Test Results Summary"
  echo "========================================"
  echo "VM: $vm_name"

  if [ $exit_code -eq 0 ]; then
    echo "Status: ✓ PASSED"
    echo "All tests passed successfully!"
  else
    echo "Status: ✗ FAILED"
    echo "Some tests failed. Please review the output above."
  fi

  echo "========================================"
  echo ""

  return $exit_code
}

function generate_unique_vm_name() {
  local prefix="${1:-kali-test}"
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local random=$(head /dev/urandom | tr -dc a-z0-9 | head -c 4)

  echo "${prefix}-${timestamp}-${random}"
}

function vm_exists() {
  local vm_name="$1"
  VBoxManage list vms | grep -q "\"$vm_name\""
}

function wait_for_vm_ready() {
  local vm_ip="$1"
  local timeout="${2:-300}"  # 5 minutes default

  echo "Waiting for VM to be ready (timeout: ${timeout}s)..."

  # Wait for SSH
  wait_for_ssh "$vm_ip"

  # Give the system a bit more time to fully boot
  echo "SSH available. Waiting for system to fully initialize..."
  sleep 10

  echo "VM is ready for testing"
}
