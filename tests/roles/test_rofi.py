"""Tests for pluggero.rofi role."""
import pytest


def test_rofi_packages_installed(host, role_packages):
    """Verify rofi packages are installed."""
    packages = role_packages('rofi')
    if not packages:
        pytest.skip("No rofi packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_rofi_command_available(host):
    """Verify rofi command is available."""
    cmd = host.run("which rofi")
    assert cmd.rc == 0, "rofi not found in PATH"
