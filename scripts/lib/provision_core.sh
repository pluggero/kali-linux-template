#!/bin/bash

function run_packer_build() {
  local var_file="$1"

  echo "Running Packer build..."

  if [[ -n "$var_file" && -f "$var_file" ]]; then
    packer build -var-file="$var_file" -force -on-error=ask "$PACKER_DIR"
  else
    packer build -force -on-error=ask "$PACKER_DIR"
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
