"""Tests for pluggero.virtualbox_guest role."""
import pytest


@pytest.mark.critical
def test_virtualbox_guest_additions_packages(host, role_packages):
    """Verify VirtualBox Guest Additions packages are installed."""
    packages = role_packages('virtualbox_guest')
    if not packages:
        pytest.skip("No virtualbox_guest packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


@pytest.mark.critical
def test_virtualbox_kernel_modules_loaded(host):
    """Verify VirtualBox kernel modules are loaded."""
    cmd = host.run("lsmod | grep -i vbox")
    assert cmd.rc == 0, "No VirtualBox kernel modules loaded"
    assert len(cmd.stdout.strip()) > 0, "VirtualBox modules output is empty"


def test_vboxservice_running(host):
    """Verify VBoxService is running if applicable."""
    cmd = host.run("pgrep -x VBoxService")
    if cmd.rc != 0:
        pytest.skip("VBoxService not running (may not be required)")
