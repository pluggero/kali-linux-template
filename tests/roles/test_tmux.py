"""Tests for pluggero.tmux role."""
import pytest


def test_tmux_packages_installed(host, role_packages):
    """Verify tmux packages are installed."""
    packages = role_packages('tmux')
    if not packages:
        pytest.skip("No tmux packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_tmux_command_available(host):
    """Verify tmux command is available."""
    cmd = host.run("which tmux")
    assert cmd.rc == 0, "tmux not found in PATH"


def test_tmux_version(host):
    """Verify tmux version can be retrieved."""
    cmd = host.run("tmux -V")
    assert cmd.rc == 0
    assert "tmux" in cmd.stdout
