"""Tests for pluggero.golang role."""
import pytest


def test_golang_packages_installed(host, role_packages):
    """Verify Go packages are installed."""
    packages = role_packages('golang')
    if not packages:
        pytest.skip("No golang packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_go_command_available(host):
    """Verify go command is available."""
    cmd = host.run("which go")
    assert cmd.rc == 0, "go not found in PATH"


def test_go_version(host):
    """Verify go version can be retrieved."""
    cmd = host.run("go version")
    assert cmd.rc == 0
    assert "go version" in cmd.stdout
