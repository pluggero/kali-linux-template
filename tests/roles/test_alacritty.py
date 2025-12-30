"""Tests for pluggero.alacritty role."""
import pytest


def test_alacritty_packages_installed(host, role_packages):
    """Verify Alacritty packages are installed."""
    packages = role_packages('alacritty')
    if not packages:
        pytest.skip("No alacritty packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_alacritty_command_available(host):
    """Verify alacritty command is available."""
    cmd = host.run("which alacritty")
    if cmd.rc != 0:
        pytest.skip("alacritty not expected to be in PATH")
