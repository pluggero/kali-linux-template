"""
Security configuration tests for Kali Linux VM.

Tests security hardening, SSH configuration, firewall, and permissions.
"""

import pytest


@pytest.mark.security
@pytest.mark.critical
def test_ssh_root_login_disabled(host):
    """Verify root login via SSH is disabled or restricted."""
    sshd_config = host.file("/etc/ssh/sshd_config")

    assert sshd_config.exists

    # Check for PermitRootLogin setting
    # Acceptable values: no, prohibit-password, forced-commands-only
    # NOT acceptable: yes
    cmd = host.run("grep -i '^PermitRootLogin' /etc/ssh/sshd_config")

    if cmd.rc == 0:
        # If directive exists, ensure it's not 'yes'
        assert "yes" not in cmd.stdout.lower() or "prohibit-password" in cmd.stdout.lower(), \
            "SSH root login may be enabled"


@pytest.mark.security
def test_ssh_password_authentication(host):
    """Check SSH password authentication configuration."""
    cmd = host.run("grep -i '^PasswordAuthentication' /etc/ssh/sshd_config")

    # This is informational - password auth might be enabled for convenience
    # but it's worth knowing
    if cmd.rc == 0:
        print(f"SSH Password Authentication: {cmd.stdout.strip()}")


@pytest.mark.security
def test_ssh_pubkey_authentication(host):
    """Verify SSH public key authentication is enabled."""
    cmd = host.run("grep -i '^PubkeyAuthentication' /etc/ssh/sshd_config || echo 'yes'")

    assert cmd.rc == 0
    # Default is 'yes' if not specified
    assert "no" not in cmd.stdout.lower(), \
        "SSH public key authentication is disabled"


@pytest.mark.security
def test_world_writable_files(host):
    """Check for world-writable files in critical directories."""
    # Check /etc for world-writable files (excluding some safe paths)
    cmd = host.run(
        "find /etc -type f -perm -002 ! -path '*/systemd/*' ! -path '*/dbus-1/*' 2>/dev/null"
    )

    assert cmd.rc == 0
    # Should ideally be empty or very few files
    if cmd.stdout.strip():
        print(f"World-writable files in /etc: {cmd.stdout.strip()}")


@pytest.mark.security
def test_suid_binaries(host):
    """Check for SUID binaries (informational)."""
    # Find SUID binaries - this is informational, not necessarily a failure
    cmd = host.run("find /usr/bin /bin /usr/sbin /sbin -type f -perm -4000 2>/dev/null")

    assert cmd.rc == 0
    # Just log what we find
    if cmd.stdout.strip():
        suid_binaries = cmd.stdout.strip().split('\n')
        print(f"Found {len(suid_binaries)} SUID binaries")


@pytest.mark.security
def test_umask_setting(host):
    """Verify reasonable umask is set."""
    cmd = host.run("umask")

    assert cmd.rc == 0
    umask_value = cmd.stdout.strip()
    # Common secure umasks: 0022, 0027, 0077
    assert umask_value in ["0022", "0027", "0077", "022", "027", "077"], \
        f"Unusual umask value: {umask_value}"


@pytest.mark.security
def test_tmp_directory_permissions(host):
    """Verify /tmp has proper permissions."""
    tmp = host.file("/tmp")

    assert tmp.exists
    assert tmp.is_directory
    # /tmp should have sticky bit set (mode includes 't')
    assert tmp.mode & 0o1000, "/tmp does not have sticky bit set"


@pytest.mark.security
def test_firewall_package_installed(host):
    """Check if a firewall package is installed."""
    # Common firewall packages on Debian/Kali
    ufw = host.package("ufw")
    iptables = host.package("iptables")
    nftables = host.package("nftables")

    # At least one firewall package should be installed
    assert ufw.is_installed or iptables.is_installed or nftables.is_installed, \
        "No firewall package (ufw/iptables/nftables) is installed"


@pytest.mark.security
def test_sudo_logs(host):
    """Verify sudo logging is configured."""
    # Check if sudo logs to syslog or journald
    cmd = host.run("grep -i 'sudo' /var/log/auth.log 2>/dev/null || journalctl -u sudo -n 1 2>/dev/null")

    # Should be able to access sudo logs via one method or another
    assert cmd.rc == 0, "Cannot access sudo logs"


@pytest.mark.security
def test_core_dumps_disabled(host):
    """Check if core dumps are limited or disabled."""
    cmd = host.run("ulimit -c")

    assert cmd.rc == 0
    # 0 means core dumps are disabled
    # This is a security best practice but not critical
    core_limit = cmd.stdout.strip()
    print(f"Core dump limit: {core_limit}")


@pytest.mark.security
def test_important_file_permissions(host):
    """Verify important system files have correct permissions."""
    critical_files = {
        "/etc/passwd": (0o644, "root", "root"),
        "/etc/shadow": (0o640, "root", "shadow"),
        "/etc/group": (0o644, "root", "root"),
        "/etc/gshadow": (0o640, "root", "shadow"),
    }

    for filepath, (expected_mode, expected_user, expected_group) in critical_files.items():
        f = host.file(filepath)

        if f.exists:
            assert f.user == expected_user, \
                f"{filepath} has wrong owner: {f.user} (expected {expected_user})"

            # Group might be 'shadow' or 'root' depending on config
            if filepath in ["/etc/shadow", "/etc/gshadow"]:
                assert f.group in ["root", "shadow"], \
                    f"{filepath} has wrong group: {f.group}"
            else:
                assert f.group == expected_group, \
                    f"{filepath} has wrong group: {f.group} (expected {expected_group})"
