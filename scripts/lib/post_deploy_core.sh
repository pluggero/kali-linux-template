#!/bin/bash

function wait_for_vm_ip() {
  local vm_name="$1"
  while true; do
    result=$(VBoxManage guestproperty get "$vm_name" "/VirtualBox/GuestInfo/Net/0/V4/IP")
    ip=$(echo "$result" | awk '{print $2}')
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$ip"
      return
    fi
    sleep 2
  done
}

function wait_for_ssh() {
  local host="$1"
  echo "Waiting for SSH to be available on $host..."
  until nc -z "$host" 22; do
    sleep 2
  done
}

function select_vm() {
  VBoxManage list vms | awk -F\" '{print $2}' | fzf --prompt="Select a VM: "
}

function ask_rename_vm() {
  local current_vm="$1"

  read -rp "Do you want to rename the VM '$current_vm'? [y/n]: " rename_choice
  rename_choice="${rename_choice,,}"

  if [[ "$rename_choice" =~ ^(y|yes)$ ]]; then
    while true; do
      read -e -p "Input new VM name: " -i "kali-" new_vm
      if [[ -z "$new_vm" ]]; then
        echo "No new name provided, exiting." >&2
        exit 1
      fi
      if VBoxManage list vms | awk -F\" '{print $2}' | grep -Fxq "$new_vm"; then
        echo "VM '$new_vm' already exists. Choose another name." >&2
      else
        VBoxManage modifyvm "$current_vm" --name "$new_vm"
        echo "$new_vm"
        return
      fi
    done
  else
    echo "$current_vm"
  fi
}

function shutdown_vm_if_running() {
  local vm="$1"
  local state
  state=$(VBoxManage showvminfo "$vm" --machinereadable | grep -i "VMState=" | cut -d '"' -f 2)
  if [[ "$state" == "running" ]]; then
    # Confirm before proceeding
    echo "The VM '$vm' will be shut down for the changes to take effect."
    read -rp "Press Enter to continue..."
    echo "Shutting down VM '$vm'..."
    VBoxManage controlvm "$vm" acpipowerbutton
    until [[ "$(VBoxManage showvminfo "$vm" --machinereadable | grep -i "VMState=" | cut -d '"' -f 2)" != "running" ]]; do
      sleep 2
    done
    echo "VM '$vm' has been powered off."
  fi
}

function add_shared_folder() {
  local vm="$1"
  local name="$2"
  local path="$3"
  local mount="$4"

  if VBoxManage showvminfo "$vm" --machinereadable | grep -q "SharedFolderNameMachineMapping.*$name"; then
    VBoxManage sharedfolder remove "$vm" --name "$name"
  fi

  VBoxManage sharedfolder add "$vm" --name "$name" --hostpath "$path" --auto-mount-point="$mount"
}
