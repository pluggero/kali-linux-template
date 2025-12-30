"""
Service status tests for Kali Linux VM.

Tests that essential services are running and properly configured.
"""

import pytest


@pytest.mark.critical
def test_ssh_service_running(host):
    """Verify SSH service is running."""
    service = host.service("ssh")

    assert service.is_running, "SSH service is not running"
    assert service.is_enabled, "SSH service is not enabled"


@pytest.mark.critical
def test_ssh_port_listening(host):
    """Verify SSH is listening on port 22."""
    socket = host.socket("tcp://0.0.0.0:22")

    assert socket.is_listening, "SSH is not listening on port 22"


def test_systemd_running(host):
    """Verify systemd is the init system."""
    cmd = host.run("ps -p 1 -o comm=")

    assert cmd.rc == 0
    assert "systemd" in cmd.stdout.strip()


def test_no_failed_services(host):
    """Check for failed systemd services."""
    cmd = host.run("systemctl --failed --no-pager")

    assert cmd.rc == 0
    # Output should be minimal if no services failed
    # Usually just shows header and footer
    lines = [line for line in cmd.stdout.split('\n') if line.strip()]
    # If there are failed services, there will be more than just header/footer
    # This is a soft check - may need adjustment based on actual output
    assert "0 loaded units listed" in cmd.stdout or len(lines) <= 3, \
        f"Some systemd services have failed:\n{cmd.stdout}"


def test_network_manager_or_networking(host):
    """Verify network is managed (either NetworkManager or networking)."""
    # Check if either NetworkManager or traditional networking is present
    nm = host.service("NetworkManager")
    networking = host.service("networking")

    # At least one should exist
    assert nm.is_running or networking.is_running, \
        "Neither NetworkManager nor networking service is running"


def test_dbus_running(host):
    """Verify D-Bus system service is running."""
    service = host.service("dbus")

    assert service.is_running, "D-Bus service is not running"


def test_cron_running(host):
    """Verify cron daemon is running."""
    service = host.service("cron")

    assert service.is_running, "Cron service is not running"


def test_rsyslog_or_journald(host):
    """Verify system logging is functional."""
    rsyslog = host.service("rsyslog")

    # Either rsyslog should be running, or journald (which is part of systemd)
    if not rsyslog.is_running:
        # Check journald is working
        cmd = host.run("journalctl --no-pager -n 10")
        assert cmd.rc == 0, "Neither rsyslog nor journald appears to be working"
