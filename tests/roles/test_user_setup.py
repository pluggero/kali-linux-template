"""Tests for pluggero.user_setup role."""
import pytest


@pytest.mark.critical
def test_kali_user_exists(host):
    """Verify the main user account exists."""
    user = host.user('kali')
    assert user.exists, "kali user does not exist"


@pytest.mark.critical
def test_kali_user_has_home_directory(host):
    """Verify user has a home directory."""
    user = host.user('kali')
    assert user.home is not None, "User home directory not set"
    
    home_dir = host.file(user.home)
    assert home_dir.exists, f"Home directory {user.home} does not exist"
    assert home_dir.is_directory, f"{user.home} is not a directory"


@pytest.mark.critical
def test_kali_user_has_sudo_access(host):
    """Verify user has sudo privileges."""
    user = host.user('kali')
    assert 'sudo' in user.groups, "kali user not in sudo group"


def test_ssh_directory_exists(host):
    """Verify SSH directory exists for the user."""
    ssh_dir = host.file('/home/kali/.ssh')
    if ssh_dir.exists:
        assert ssh_dir.is_directory
        assert ssh_dir.mode == 0o700, "SSH directory has incorrect permissions"


def test_authorized_keys_exists(host):
    """Verify authorized_keys file exists if configured."""
    auth_keys = host.file('/home/kali/.ssh/authorized_keys')
    if auth_keys.exists:
        assert auth_keys.user == 'kali'
        assert auth_keys.mode & 0o077 == 0, "authorized_keys has incorrect permissions"
