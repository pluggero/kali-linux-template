"""
Tests for pluggero.neovim role.

This role installs Neovim and configures it with a custom config.
Tests use configuration from ansible/vars/neovim.yml and role vars.
"""

import pytest


def test_neovim_packages_installed(host, role_packages):
    """Verify Neovim-related packages are installed."""
    packages = role_packages('neovim')

    if not packages:
        pytest.skip("No neovim packages configured")

    failed_packages = []
    for pkg in packages:
        if not host.package(pkg).is_installed:
            failed_packages.append(pkg)

    if failed_packages:
        pytest.fail(
            f"The following Neovim packages are not installed:\n" +
            "\n".join(f"  - {pkg}" for pkg in failed_packages)
        )


def test_neovim_command_available(host):
    """Verify nvim command is available."""
    cmd = host.run("which nvim")
    assert cmd.rc == 0, "nvim command not found in PATH"


def test_neovim_version(host):
    """Verify Neovim is installed and returns version."""
    cmd = host.run("nvim --version")
    assert cmd.rc == 0, "Failed to get Neovim version"
    assert "NVIM" in cmd.stdout


def test_neovim_config_directory(host, role_config):
    """Verify Neovim config directory exists."""
    config = role_config('neovim')

    config_dir = config.get('neovim_config_dir')
    if config_dir:
        # Expand the path if it contains shell variables
        cmd = host.run(f"test -d {config_dir}")
        assert cmd.rc == 0, f"Neovim config directory {config_dir} does not exist"


def test_neovim_dependencies_installed(host, role_packages):
    """Verify Neovim dependencies are installed."""
    packages = role_packages('neovim')

    # Common dependencies
    expected_deps = ['git', 'npm', 'unzip']

    for dep in expected_deps:
        if dep in packages:
            # Check if the package is installed
            assert host.package(dep).is_installed, \
                f"Neovim dependency '{dep}' is not installed"


def test_neovim_can_start(host):
    """Verify Neovim can start (basic smoke test)."""
    # Try to start nvim with --version (safe, no UI)
    cmd = host.run("nvim --headless +quit")
    assert cmd.rc == 0, "Neovim failed to start"
