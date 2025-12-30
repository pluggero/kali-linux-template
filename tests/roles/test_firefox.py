"""Tests for pluggero.firefox role."""
import pytest


def test_firefox_packages_installed(host, role_packages):
    """Verify Firefox packages are installed."""
    packages = role_packages('firefox')
    if not packages:
        pytest.skip("No firefox packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_firefox_command_available(host):
    """Verify firefox command is available."""
    cmd = host.run("which firefox || which firefox-esr")
    assert cmd.rc == 0, "firefox not found in PATH"
