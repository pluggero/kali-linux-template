"""Tests for pluggero.i3wm role."""
import pytest


def test_i3wm_packages_installed(host, role_packages):
    """Verify i3 window manager packages are installed."""
    packages = role_packages('i3wm')
    if not packages:
        pytest.skip("No i3wm packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_i3_command_available(host):
    """Verify i3 command is available."""
    cmd = host.run("which i3")
    assert cmd.rc == 0, "i3 not found in PATH"
