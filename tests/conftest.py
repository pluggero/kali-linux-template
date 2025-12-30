"""
Pytest configuration for Kali Linux VM testing.

This module provides fixtures and configuration for testinfra-based
infrastructure tests.
"""

import os
import sys
from pathlib import Path
import pytest

# Add tests directory to Python path
tests_dir = Path(__file__).parent
if str(tests_dir) not in sys.path:
    sys.path.insert(0, str(tests_dir))

from ansible_parser import AnsibleDataLoader


@pytest.fixture(scope='session')
def host(request):
    """
    Provide the host connection string for testinfra.

    This fixture reads from environment variables set by the test script:
    - KALI_VM_IP: The IP address of the test VM
    - KALI_SSH_USER: SSH username (default: kali)
    - KALI_SSH_KEY: Path to SSH private key (optional)

    Returns:
        str: SSH connection string in the format ssh://user@host
    """
    vm_ip = os.environ.get('KALI_VM_IP')
    if not vm_ip:
        pytest.fail("KALI_VM_IP environment variable not set. Run tests via ./scripts/kali_test.sh")

    ssh_user = os.environ.get('KALI_SSH_USER', 'kali')

    return f"ssh://{ssh_user}@{vm_ip}"


@pytest.fixture(scope='session')
def vm_ip():
    """
    Provide the VM IP address for tests that need it directly.

    Returns:
        str: IP address of the test VM
    """
    vm_ip = os.environ.get('KALI_VM_IP')
    if not vm_ip:
        pytest.fail("KALI_VM_IP environment variable not set")
    return vm_ip


@pytest.fixture(scope='session')
def ssh_user():
    """
    Provide the SSH username.

    Returns:
        str: SSH username (default: kali)
    """
    return os.environ.get('KALI_SSH_USER', 'kali')


def pytest_configure(config):
    """
    Register custom pytest markers.
    """
    config.addinivalue_line(
        "markers", "critical: mark test as critical (must pass)"
    )
    config.addinivalue_line(
        "markers", "security: mark test as security-related"
    )
    config.addinivalue_line(
        "markers", "network: mark test as network-related"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow-running"
    )


def pytest_collection_modifyitems(config, items):
    """
    Modify test collection to add markers based on test location.
    """
    for item in items:
        # Add markers based on test location
        if "roles/" in item.nodeid:
            item.add_marker(pytest.mark.role)
        elif "integration/" in item.nodeid:
            item.add_marker(pytest.mark.integration)

        # Add markers based on test file names
        if "test_security" in item.nodeid:
            item.add_marker(pytest.mark.security)
        elif "test_networking" in item.nodeid:
            item.add_marker(pytest.mark.network)


# ==============================================================================
# Ansible Data Fixtures
# ==============================================================================

@pytest.fixture(scope='session')
def ansible_data():
    """
    Load Ansible configuration data once per test session.

    This fixture parses all Ansible playbooks, roles, and vars files
    to provide a single source of truth for test data.

    Returns:
        AnsibleDataLoader: Loader instance for accessing ansible data
    """
    return AnsibleDataLoader()


@pytest.fixture(scope='session')
def installed_roles(ansible_data):
    """
    Get list of all roles installed by provisioning playbooks.

    Returns:
        list: List of role names (e.g., ['pluggero.docker', ...])
    """
    return ansible_data.get_all_roles()


@pytest.fixture
def role_packages(ansible_data):
    """
    Get packages for a specific role.

    Returns:
        callable: Function that takes role_name and returns list of packages

    Example:
        def test_docker_packages(host, role_packages):
            for pkg in role_packages('docker'):
                assert host.package(pkg).is_installed
    """
    def _get_packages(role_name):
        return ansible_data.get_role_packages(role_name)
    return _get_packages


@pytest.fixture
def role_config(ansible_data):
    """
    Get configuration for a specific role.

    Returns:
        callable: Function that takes role_name and returns config dict

    Example:
        def test_docker_service(host, role_config):
            config = role_config('docker')
            if config.get('docker_service_enabled'):
                assert host.service('docker').is_enabled
    """
    def _get_config(role_name):
        return ansible_data.get_role_config(role_name)
    return _get_config


@pytest.fixture
def role_data(ansible_data):
    """
    Get comprehensive data for a specific role.

    Returns:
        callable: Function that takes role_name and returns RoleData

    Example:
        def test_role(host, role_data):
            data = role_data('docker')
            assert data.packages
            assert data.config
    """
    def _get_role_data(role_name):
        return ansible_data.get_role_data(role_name)
    return _get_role_data


@pytest.fixture(scope='session')
def tool_installer_tools(ansible_data):
    """
    Get all tools from tool_installer configuration.

    Returns:
        list: List of tool configuration dicts
    """
    return ansible_data.get_tool_installer_tools()


@pytest.fixture(scope='session')
def python_tools(ansible_data):
    """
    Get all Python tools from python role configuration.

    Returns:
        list: List of Python tool configuration dicts
    """
    return ansible_data.get_python_tools()
