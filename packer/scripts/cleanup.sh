#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning apt cache..."
apt-get clean -y
rm -rf /var/lib/apt/lists/*
touch -d @0 /var/lib/apt/lists

echo "Vacuuming journal logs..."
journalctl --vacuum-size=1M || true

echo "Zeroing free disk space for better compression..."
dd if=/dev/zero of=/EMPTY bs=4M status=progress || true
sync
rm /EMPTY
sync

echo "Cleanup complete"
