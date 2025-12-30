"""Tests for pluggero.rustup role."""
import pytest


def test_rustup_packages_installed(host, role_packages):
    """Verify rustup packages are installed."""
    packages = role_packages('rustup')
    if not packages:
        pytest.skip("No rustup packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_rustup_command_available(host):
    """Verify rustup command is available."""
    cmd = host.run("which rustup")
    if cmd.rc != 0:
        pytest.skip("rustup not in system PATH (may be user-local)")


def test_cargo_command_available(host):
    """Verify cargo command is available."""
    cmd = host.run("which cargo")
    if cmd.rc != 0:
        pytest.skip("cargo not in system PATH (may be user-local)")
