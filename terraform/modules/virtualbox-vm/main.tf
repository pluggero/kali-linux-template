terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

locals {
  vm_full_name = "${var.vm_name}-${var.env}"
  ovf_file     = replace(var.box_file, ".box", ".ovf")
  ovf_dir      = dirname(var.box_file)
}

# Import the VM from OVF
resource "null_resource" "import_vm" {
  triggers = {
    vm_name  = local.vm_full_name
    box_file = var.box_file
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if VM already exists
      if VBoxManage list vms | grep -q '"${local.vm_full_name}"'; then
        echo "VM ${local.vm_full_name} already exists, removing..."
        VBoxManage unregistervm "${local.vm_full_name}" --delete || true
      fi

      # Import the OVF file
      VBoxManage import "${local.ovf_file}" \
        --vsys 0 --vmname "${local.vm_full_name}" \
        --vsys 0 --cpus ${var.cpus} \
        --vsys 0 --memory ${var.memory}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "VBoxManage unregistervm '${self.triggers.vm_name}' --delete || true"
  }
}

# Configure VM settings
resource "null_resource" "configure_vm" {
  triggers = {
    vm_name = local.vm_full_name
    config  = "${var.cpus}-${var.memory}-${var.vram}-${var.bridged_adapter}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      VBoxManage modifyvm "${local.vm_full_name}" \
        --cpus ${var.cpus} \
        --memory ${var.memory} \
        --vram ${var.vram} \
        --graphicscontroller ${var.graphics_controller} \
        --clipboard-mode ${var.clipboard_mode} \
        --accelerate-3d off \
        --nic1 bridged \
        --bridgeadapter1 ${var.bridged_adapter}
    EOT
  }

  depends_on = [null_resource.import_vm]
}

# Start the VM
resource "null_resource" "start_vm" {
  triggers = {
    vm_name    = local.vm_full_name
    start_time = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if VM is already running
      if VBoxManage showvminfo "${local.vm_full_name}" --machinereadable | grep -q 'VMState="running"'; then
        echo "VM is already running"
      else
        echo "Starting VM..."
        VBoxManage startvm "${local.vm_full_name}" --type headless
        echo "Waiting for VM to start..."
        sleep 10
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      VBoxManage controlvm '${self.triggers.vm_name}' poweroff || true
      sleep 2
    EOT
  }

  depends_on = [null_resource.configure_vm]
}

# Get VM IP address from bridged interface
resource "null_resource" "get_vm_info" {
  triggers = {
    vm_id = null_resource.start_vm.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for VM to get IP address..."
      for i in {1..30}; do
        IP=$(VBoxManage guestproperty get "${local.vm_full_name}" "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{print $2}')
        if [ "$IP" != "No" ] && [ -n "$IP" ]; then
          echo "VM IP Address: $IP"
          break
        fi
        sleep 2
      done
    EOT
  }

  depends_on = [null_resource.start_vm]
}

# Optional: Run post-deployment configuration
resource "null_resource" "post_deploy" {
  count = var.run_post_deploy && var.post_deploy_script != "" ? 1 : 0

  triggers = {
    vm_id = null_resource.get_vm_info.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "==============================================="
      echo "Running post-deployment configuration..."
      echo "==============================================="
      ${var.post_deploy_script}
    EOT
  }

  depends_on = [null_resource.get_vm_info]
}
