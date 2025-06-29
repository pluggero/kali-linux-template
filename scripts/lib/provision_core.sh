#!/bin/bash

function run_packer_build() {
  echo "Running Packer build..."
  packer build -force -on-error=ask "$PACKER_DIR"
  return $?
}

function get_latest_output_dir() {
  find "$1" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" | sort -nr | head -n 1 | cut -d' ' -f2-
}

function tag_output_with_commit() {
  local output_dir="$1"
  local commit_hash
  commit_hash=$(git rev-parse HEAD)
  echo "$commit_hash" > "$output_dir/version.txt"
  echo "Written commit $commit_hash to $output_dir/version.txt"
}
