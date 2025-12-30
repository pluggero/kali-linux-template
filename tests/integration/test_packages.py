"""
Package installation tests for Kali Linux VM.

Tests that essential system packages and Kali-specific tools are installed.
"""

import pytest


@pytest.mark.critical
@pytest.mark.parametrize("pkg", [
    "openssh-server",
    "sudo",
    "curl",
    "wget",
    "git",
    "vim",
    "net-tools",
])
def test_essential_packages(host, pkg):
    """Verify essential system packages are installed."""
    package = host.package(pkg)
    assert package.is_installed, f"Package '{pkg}' is not installed"


@pytest.mark.parametrize("pkg", [
    "nmap",
    "netcat-traditional",
    "dnsutils",
    "iputils-ping",
    "iproute2",
])
def test_network_tools(host, pkg):
    """Verify networking tools are installed."""
    package = host.package(pkg)
    assert package.is_installed, f"Network tool '{pkg}' is not installed"


@pytest.mark.parametrize("pkg", [
    "python3",
    "python3-pip",
])
def test_python_packages(host, pkg):
    """Verify Python is installed."""
    package = host.package(pkg)
    assert package.is_installed, f"Python package '{pkg}' is not installed"


def test_python_version(host):
    """Verify Python 3 is available and working."""
    cmd = host.run("python3 --version")

    assert cmd.rc == 0
    assert "Python 3" in cmd.stdout


def test_pip_version(host):
    """Verify pip is available and working."""
    cmd = host.run("pip3 --version")

    assert cmd.rc == 0
    assert "pip" in cmd.stdout.lower()


@pytest.mark.parametrize("pkg", [
    "build-essential",
    "gcc",
    "make",
])
def test_build_tools(host, pkg):
    """Verify build tools are installed."""
    package = host.package(pkg)
    assert package.is_installed, f"Build tool '{pkg}' is not installed"


def test_virtualbox_guest_additions(host):
    """Verify VirtualBox Guest Additions kernel modules are loaded."""
    cmd = host.run("lsmod | grep -i vbox")

    # At least one VirtualBox module should be loaded
    # Common modules: vboxguest, vboxsf, vboxvideo
    assert cmd.rc == 0, "No VirtualBox kernel modules found"
    assert len(cmd.stdout.strip()) > 0


def test_dpkg_database(host):
    """Verify dpkg database is not corrupted."""
    cmd = host.run("dpkg --audit")

    # dpkg --audit should return 0 if no issues
    assert cmd.rc == 0, "dpkg database has issues"
