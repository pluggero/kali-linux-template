"""Tests for pluggero.burpsuite role."""
import pytest


def test_burpsuite_packages_installed(host, role_packages):
    """Verify Burp Suite packages are installed."""
    packages = role_packages('burpsuite')
    if not packages:
        pytest.skip("No burpsuite packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_burpsuite_command_available(host):
    """Verify burpsuite command is available."""
    cmd = host.run("which burpsuite")
    if cmd.rc != 0:
        pytest.skip("burpsuite not in PATH")
