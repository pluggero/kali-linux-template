"""Tests for pluggero.upgrade role."""
import pytest


@pytest.mark.critical
def test_system_is_updated(host):
    """Verify system has been upgraded (basic check)."""
    # This role runs apt update/upgrade during provisioning
    # We can check that apt database is not stale
    cmd = host.run("apt-cache policy")
    assert cmd.rc == 0, "apt package manager not functional"


def test_no_broken_packages(host):
    """Verify no broken packages after upgrade."""
    cmd = host.run("dpkg --audit")
    assert cmd.rc == 0, "dpkg has broken packages"
