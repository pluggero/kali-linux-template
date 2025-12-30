#!/bin/bash
set -euo pipefail

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

function terraform_init() {
  local env_dir="$1"
  echo "Initializing Terraform in $env_dir..."
  cd "$env_dir"
  terraform init
  cd - > /dev/null
}

function terraform_plan() {
  local env_dir="$1"
  shift
  local extra_args=("$@")

  echo "Planning Terraform deployment in $env_dir..."
  cd "$env_dir"
  terraform plan "${extra_args[@]}"
  cd - > /dev/null
}

function terraform_apply() {
  local env_dir="$1"
  shift
  local extra_args=("$@")

  echo "Applying Terraform deployment in $env_dir..."
  cd "$env_dir"
  terraform apply "${extra_args[@]}"
  cd - > /dev/null
}

function terraform_destroy() {
  local env_dir="$1"
  shift
  local extra_args=("$@")

  echo "Destroying Terraform deployment in $env_dir..."
  cd "$env_dir"
  terraform destroy "${extra_args[@]}"
  cd - > /dev/null
}
