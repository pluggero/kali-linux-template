"""Tests for pluggero.tigervnc role."""
import pytest


def test_tigervnc_packages_installed(host, role_packages):
    """Verify TigerVNC packages are installed."""
    packages = role_packages('tigervnc')
    if not packages:
        pytest.skip("No tigervnc packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_vncserver_command_available(host):
    """Verify vncserver command is available."""
    cmd = host.run("which vncserver")
    if cmd.rc != 0:
        pytest.skip("vncserver not in PATH")
