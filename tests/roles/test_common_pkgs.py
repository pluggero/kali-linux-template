"""
Tests for pluggero.common_pkgs role.

This role installs common system packages defined in ansible/vars/common_pkgs.yml.
Tests automatically use the package list from Ansible configuration.
"""

import pytest


@pytest.mark.parametrize("pkg", [
    pytest.param(pkg, id=pkg)
    for pkg in []  # Will be populated dynamically
])
def test_common_packages_installed(host, pkg):
    """Verify common packages from ansible config are installed."""
    package = host.package(pkg)
    assert package.is_installed, f"Package '{pkg}' is not installed"


def test_common_packages_from_ansible(host, role_packages):
    """Test all common packages defined in ansible configuration."""
    packages = role_packages('common_pkgs')

    # Should have some packages defined
    assert len(packages) > 0, "No packages found in common_pkgs configuration"

    # Test each package
    failed_packages = []
    for pkg in packages:
        if not host.package(pkg).is_installed:
            failed_packages.append(pkg)

    # Report all failures at once
    if failed_packages:
        pytest.fail(
            f"The following common packages are not installed:\n" +
            "\n".join(f"  - {pkg}" for pkg in failed_packages)
        )


def test_essential_tools_in_path(host):
    """Verify essential tools are available in PATH."""
    essential_tools = [
        'nmap', 'jq', 'rsync', 'zip', 'unzip',
        'ripgrep', 'xclip', 'xxd'
    ]

    missing_tools = []
    for tool in essential_tools:
        cmd = host.run(f"which {tool}")
        if cmd.rc != 0:
            missing_tools.append(tool)

    if missing_tools:
        pytest.fail(
            f"Essential tools not found in PATH:\n" +
            "\n".join(f"  - {tool}" for tool in missing_tools)
        )


def test_metasploit_framework_available(host, role_packages):
    """Verify Metasploit Framework is installed if configured."""
    packages = role_packages('common_pkgs')

    if 'metasploit-framework' in packages:
        # Check package is installed
        assert host.package('metasploit-framework').is_installed

        # Check msfconsole is in PATH
        cmd = host.run("which msfconsole")
        assert cmd.rc == 0, "msfconsole not found in PATH"


def test_network_tools_available(host, role_packages):
    """Verify networking tools are available."""
    packages = role_packages('common_pkgs')

    network_tools = {
        'nmap': 'nmap',
        'netexec': 'netexec',
        'enum4linux': 'enum4linux',
        'wafw00f': 'wafw00f',
    }

    for pkg, tool in network_tools.items():
        if pkg in packages:
            # Verify tool is in PATH
            cmd = host.run(f"which {tool}")
            assert cmd.rc == 0, f"Tool '{tool}' from package '{pkg}' not in PATH"
