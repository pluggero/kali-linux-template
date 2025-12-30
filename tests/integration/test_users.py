"""
User and authentication tests for Kali Linux VM.

Tests user accounts, groups, SSH configuration, and sudo access.
"""

import pytest


@pytest.mark.critical
def test_kali_user_exists(host):
    """Verify kali user exists."""
    user = host.user("kali")

    assert user.exists, "User 'kali' does not exist"
    assert user.name == "kali"


@pytest.mark.critical
def test_kali_user_home_directory(host):
    """Verify kali user has a home directory."""
    user = host.user("kali")

    assert user.home is not None
    home_dir = host.file(user.home)
    assert home_dir.exists
    assert home_dir.is_directory
    assert home_dir.user == "kali"


@pytest.mark.critical
def test_kali_user_shell(host):
    """Verify kali user has a valid shell."""
    user = host.user("kali")

    assert user.shell is not None
    # Common shells: bash, zsh, fish
    assert user.shell in ["/bin/bash", "/usr/bin/bash", "/bin/zsh", "/usr/bin/zsh", "/bin/fish", "/usr/bin/fish"]


@pytest.mark.critical
def test_kali_user_in_sudo_group(host):
    """Verify kali user is in sudo group."""
    user = host.user("kali")

    assert "sudo" in user.groups, "User 'kali' is not in sudo group"


def test_root_user_exists(host):
    """Verify root user exists."""
    user = host.user("root")

    assert user.exists
    assert user.uid == 0


def test_sudo_configuration(host):
    """Verify sudo is properly configured."""
    sudoers = host.file("/etc/sudoers")

    assert sudoers.exists
    assert sudoers.user == "root"
    assert sudoers.group == "root"
    assert sudoers.mode == 0o440


def test_kali_user_sudo_access(host):
    """Verify kali user can use sudo."""
    cmd = host.run("sudo -l -U kali")

    assert cmd.rc == 0, "Failed to check sudo permissions for kali user"


@pytest.mark.critical
def test_ssh_directory_exists(host):
    """Verify SSH directory exists in kali home."""
    user = host.user("kali")
    ssh_dir = host.file(f"{user.home}/.ssh")

    assert ssh_dir.exists
    assert ssh_dir.is_directory
    assert ssh_dir.user == "kali"
    assert ssh_dir.mode == 0o700


def test_authorized_keys_file(host):
    """Verify authorized_keys file exists if SSH keys were configured."""
    user = host.user("kali")
    auth_keys = host.file(f"{user.home}/.ssh/authorized_keys")

    # This might not exist if no keys were configured during build
    # So this is a soft check
    if auth_keys.exists:
        assert auth_keys.user == "kali"
        assert auth_keys.mode in [0o600, 0o644]


def test_passwd_file_permissions(host):
    """Verify /etc/passwd has correct permissions."""
    passwd = host.file("/etc/passwd")

    assert passwd.exists
    assert passwd.user == "root"
    assert passwd.group == "root"
    assert passwd.mode == 0o644


def test_shadow_file_permissions(host):
    """Verify /etc/shadow has correct permissions."""
    shadow = host.file("/etc/shadow")

    assert shadow.exists
    assert shadow.user == "root"
    # Group can be either root or shadow depending on distribution
    assert shadow.group in ["root", "shadow"]
    assert shadow.mode == 0o640 or shadow.mode == 0o000


def test_group_file_permissions(host):
    """Verify /etc/group has correct permissions."""
    group = host.file("/etc/group")

    assert group.exists
    assert group.user == "root"
    assert group.group == "root"
    assert group.mode == 0o644


def test_no_empty_passwords(host):
    """Verify no users have empty passwords."""
    cmd = host.run("awk -F: '($2 == \"\") {print $1}' /etc/shadow")

    assert cmd.rc == 0
    # Should return empty output
    assert len(cmd.stdout.strip()) == 0, \
        f"Users with empty passwords found: {cmd.stdout.strip()}"
