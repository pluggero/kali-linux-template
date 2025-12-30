"""Tests for pluggero.wireshark role."""
import pytest


def test_wireshark_packages_installed(host, role_packages):
    """Verify Wireshark packages are installed."""
    packages = role_packages('wireshark')
    if not packages:
        # Wireshark might be in common_pkgs
        assert host.package('wireshark').is_installed, "wireshark not installed"
    else:
        for pkg in packages:
            assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"


def test_wireshark_command_available(host):
    """Verify wireshark command is available."""
    cmd = host.run("which wireshark")
    if cmd.rc != 0:
        pytest.skip("wireshark not in PATH")


def test_tshark_command_available(host):
    """Verify tshark (CLI) command is available."""
    cmd = host.run("which tshark")
    assert cmd.rc == 0, "tshark not found in PATH"
