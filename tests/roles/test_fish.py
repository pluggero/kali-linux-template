"""Tests for pluggero.fish role."""
import pytest


def test_fish_packages_installed(host, role_packages):
    """Verify Fish shell packages are installed."""
    packages = role_packages('fish')
    if not packages:
        pytest.skip("No fish packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_fish_command_available(host):
    """Verify fish command is available."""
    cmd = host.run("which fish")
    assert cmd.rc == 0, "fish not found in PATH"


def test_fish_is_valid_shell(host):
    """Verify fish is a valid login shell."""
    cmd = host.run("grep -q /fish /etc/shells")
    assert cmd.rc == 0, "fish not listed in /etc/shells"
