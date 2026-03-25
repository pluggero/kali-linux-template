#!/bin/bash

function validate_build_targets() {
  local valid_targets=("base" "qemu" "virtualbox" "vmware" "all")

  # Check if empty
  if [[ $# -eq 0 ]]; then
    echo "Error: No build targets specified"
    return 1
  fi

  # Validate each target
  for target in "$@"; do
    local valid=false
    for valid_target in "${valid_targets[@]}"; do
      if [[ "$target" == "$valid_target" ]]; then
        valid=true
        break
      fi
    done

    if [[ "$valid" == false ]]; then
      echo "Error: Invalid build target '$target'"
      echo "Valid targets: ${valid_targets[*]}"
      return 1
    fi
  done

  return 0
}

function check_base_image_exists() {
  # Check if base image exists for TODAY's date
  # Packer uses timestamp() which generates today's date in the output path
  # Format: kali-linux-VERSION-YYYYMMDD-x86_64/base/
  local today=$(date +%Y%m%d)
  local base_pattern="$OUTPUT_DIR/*-${today}-*/base"

  # Check if today's base directory exists and contains both required files
  local base_dirs=$(find "$OUTPUT_DIR" -type d -path "*-${today}-*/base" 2>/dev/null)

  if [[ -z "$base_dirs" ]]; then
    return 1
  fi

  # Check if base directory contains both qcow2 and sha256 files
  for dir in $base_dirs; do
    if ls "$dir"/*.qcow2 &>/dev/null && ls "$dir"/*.qcow2.sha256 &>/dev/null; then
      return 0
    fi
  done

  return 1
}

function check_platform_dependencies() {
  local platform_targets=("qemu" "virtualbox" "vmware")

  # Check if any platform target is requested
  local has_platform=false
  local has_base=false

  for target in "$@"; do
    # Check if target is a platform
    for platform in "${platform_targets[@]}"; do
      if [[ "$target" == "$platform" ]]; then
        has_platform=true
        break
      fi
    done

    # Check if base is included
    if [[ "$target" == "base" || "$target" == "all" ]]; then
      has_base=true
    fi
  done

  # If platform target requested without base, check if base exists
  if [[ "$has_platform" == true && "$has_base" == false ]]; then
    if ! check_base_image_exists; then
      local today=$(date +%Y%m%d)
      echo "Error: Platform targets (qemu, virtualbox, vmware) require base image to exist"
      echo "Base image for today ($today) not found in $OUTPUT_DIR/*-${today}-*/base/"
      echo "Please build base first: ./scripts/kali_provision.sh -t base"
      return 1
    fi
  fi

  return 0
}

function build_packer_only_flag() {
  local only_patterns=()

  # Handle 'all' special case - return empty string (no -only flag)
  if [[ $# -eq 1 && "$1" == "all" ]]; then
    echo ""
    return 0
  fi

  # Map each target to packer build name pattern
  for target in "$@"; do
    # Map user-friendly name to Packer build name
    case "$target" in
      base)
        only_patterns+=("base.*")
        ;;
      qemu)
        only_patterns+=("qemu.*")
        ;;
      virtualbox)
        only_patterns+=("virtualbox.*")
        ;;
      vmware)
        only_patterns+=("vmware.*")
        ;;
    esac
  done

  # Join patterns with comma for packer -only flag
  local joined_patterns=$(IFS=','; echo "${only_patterns[*]}")
  echo "-only=$joined_patterns"
}

function run_sequential_builds() {
  local var_file="$1"
  local build_order=("base" "qemu" "virtualbox" "vmware")

  echo "Building all targets sequentially: ${build_order[*]}"

  for target in "${build_order[@]}"; do
    echo ""
    echo "=========================================="
    echo "Building target: $target"
    echo "=========================================="

    local only_flag=$(build_packer_only_flag "$target")

    if [[ -n "$var_file" && -f "$var_file" ]]; then
      packer build -var-file="$var_file" -force -on-error=ask $only_flag "$PACKER_DIR"
    else
      packer build -force -on-error=ask $only_flag "$PACKER_DIR"
    fi

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      echo "Error: Build failed for target '$target'"
      return $exit_code
    fi

    echo "Successfully completed build for target: $target"
  done

  echo ""
  echo "=========================================="
  echo "All builds completed successfully"
  echo "=========================================="
  return 0
}

function run_packer_build() {
  local var_file="$1"
  shift  # Remove first argument, remaining args are build targets

  # Default to 'all' if no targets specified
  local build_targets=("$@")
  if [[ ${#build_targets[@]} -eq 0 ]]; then
    build_targets=("all")
  fi

  # Set BUILD_DATE once for all builds in this session
  export BUILD_DATE=$(date +%Y%m%d)

  echo "Running Packer build for target(s): ${build_targets[*]}"
  echo "Using build date: $BUILD_DATE"

  # Set custom TMPDIR if PACKER_TMPDIR is defined
  if [[ -n "${PACKER_TMPDIR:-}" ]]; then
    # Check if custom tmp directory exists
    if [[ ! -d "$PACKER_TMPDIR" ]]; then
      echo "Error: Custom tmp directory does not exist: $PACKER_TMPDIR"
      echo "Please create it manually before running the build"
      return 1
    fi

    # Export TMPDIR for Packer to use
    export TMPDIR="$PACKER_TMPDIR"
    echo "Using TMPDIR: $TMPDIR"
  fi

  # Handle 'all' target with sequential builds
  if [[ ${#build_targets[@]} -eq 1 && "${build_targets[0]}" == "all" ]]; then
    run_sequential_builds "$var_file"
    return $?
  fi

  # Build specific target(s)
  local only_flag=$(build_packer_only_flag "${build_targets[@]}")

  if [[ -n "$var_file" && -f "$var_file" ]]; then
    packer build -var-file="$var_file" -force -on-error=ask $only_flag "$PACKER_DIR"
  else
    packer build -force -on-error=ask $only_flag "$PACKER_DIR"
  fi

  return $?
}

function get_latest_output_dir() {
  find "$1" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" | sort -nr | head -n 1 | cut -d' ' -f2-
}

function tag_output_with_commit() {
  local output_dir="$1"
  local git_dir="."
  local commit_hash
  
  # If we're in a submodule, find the root repository
  while [[ -f "$git_dir/.git" ]]; do
    git_dir="$git_dir/.."
  done
  
  commit_hash=$(git -C "$git_dir" rev-parse HEAD)
  echo "$commit_hash" > "$output_dir/version.txt"
  echo "Written commit $commit_hash to $output_dir/version.txt"
}
