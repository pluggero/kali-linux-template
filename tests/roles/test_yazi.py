"""Tests for pluggero.yazi role."""
import pytest


def test_yazi_packages_installed(host, role_packages):
    """Verify yazi packages are installed."""
    packages = role_packages('yazi')
    if not packages:
        pytest.skip("No yazi packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_yazi_command_available(host):
    """Verify yazi command is available."""
    cmd = host.run("which yazi")
    if cmd.rc != 0:
        pytest.skip("yazi not in PATH")
