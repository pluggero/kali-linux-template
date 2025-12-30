"""
Tests for pluggero.docker role.

This role installs and configures Docker and Docker Compose.
Tests use configuration from ansible/vars/docker.yml and role vars.
"""

import pytest


def test_docker_packages_installed(host, role_packages):
    """Verify all Docker-related packages are installed."""
    packages = role_packages('docker')

    if not packages:
        pytest.skip("No docker packages configured")

    failed_packages = []
    for pkg in packages:
        if not host.package(pkg).is_installed:
            failed_packages.append(pkg)

    if failed_packages:
        pytest.fail(
            f"The following Docker packages are not installed:\n" +
            "\n".join(f"  - {pkg}" for pkg in failed_packages)
        )


def test_docker_command_available(host):
    """Verify docker command is available."""
    cmd = host.run("which docker")
    assert cmd.rc == 0, "docker command not found in PATH"


def test_docker_version(host):
    """Verify docker is installed and returns version."""
    cmd = host.run("docker --version")
    assert cmd.rc == 0, "Failed to get docker version"
    assert "Docker version" in cmd.stdout


def test_docker_compose_available(host, role_config):
    """Verify docker-compose is available if configured."""
    config = role_config('docker')

    # Check if docker-compose installation is configured
    if config.get('docker_compose_installation', False):
        cmd = host.run("docker compose version")
        assert cmd.rc == 0, "docker compose command not available"


def test_docker_service_configured(host, role_config):
    """Verify docker service is configured according to ansible vars."""
    config = role_config('docker')

    # Only check service if it's managed
    if config.get('docker_service_manage', False):
        service = host.service('docker')

        # Check if service should be enabled
        if config.get('docker_service_enabled', False):
            assert service.is_enabled, "docker service is not enabled"
            assert service.is_running, "docker service is not running"


def test_docker_group_exists(host):
    """Verify docker group exists for user permissions."""
    group = host.group('docker')
    assert group.exists, "docker group does not exist"


def test_user_in_docker_group(host, role_config):
    """Verify configured users are in docker group."""
    config = role_config('docker')

    docker_users = config.get('docker_users', [])

    if not docker_users:
        pytest.skip("No docker users configured")

    for username in docker_users:
        user = host.user(username)
        if user.exists:
            assert 'docker' in user.groups, \
                f"User '{username}' is not in docker group"


def test_docker_socket_permissions(host):
    """Verify docker socket has correct permissions."""
    socket = host.file('/var/run/docker.sock')

    if socket.exists:
        # Socket should be owned by root:docker
        assert socket.user == 'root'
        assert socket.group == 'docker'
