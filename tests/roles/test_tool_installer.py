"""
Tests for pluggero.tool_installer role.

This role installs custom tools from Git repositories.
Tests use configuration from ansible/vars/tool_installer.yml.
"""

import pytest


def test_tool_installer_tools_from_ansible(host, tool_installer_tools):
    """Verify all tools from tool_installer config are available."""
    if not tool_installer_tools:
        pytest.skip("No tool_installer tools configured")

    failed_tools = []

    for tool in tool_installer_tools:
        tool_name = tool['name']
        executables = tool.get('executables', [])

        # Check each executable
        for executable_config in executables:
            if isinstance(executable_config, dict):
                executable_name = executable_config.get('name')
            else:
                executable_name = executable_config

            if executable_name:
                cmd = host.run(f"which {executable_name}")
                if cmd.rc != 0:
                    failed_tools.append(f"{tool_name} (executable: {executable_name})")

    if failed_tools:
        pytest.fail(
            f"The following tool_installer tools are not in PATH:\n" +
            "\n".join(f"  - {tool}" for tool in failed_tools)
        )


def test_jwt_tool_available(host, tool_installer_tools):
    """Verify jwt_tool is installed if configured."""
    jwt_tool = next((t for t in tool_installer_tools if t['name'] == 'jwt_tool'), None)

    if not jwt_tool:
        pytest.skip("jwt_tool not configured")

    # Check jwt_tool is in PATH
    cmd = host.run("which jwt_tool")
    assert cmd.rc == 0, "jwt_tool not found in PATH"

    # Verify it can run
    cmd = host.run("jwt_tool --help")
    assert cmd.rc == 0, "jwt_tool failed to run"


def test_profi_available(host, tool_installer_tools):
    """Verify profi is installed if configured."""
    profi = next((t for t in tool_installer_tools if t['name'] == 'profi'), None)

    if not profi:
        pytest.skip("profi not configured")

    # Check profi is in PATH
    cmd = host.run("which profi")
    assert cmd.rc == 0, "profi not found in PATH"


def test_tool_installer_dependency_packages(host, tool_installer_tools):
    """Verify dependency packages for tools are installed."""
    if not tool_installer_tools:
        pytest.skip("No tool_installer tools configured")

    failed_packages = []

    for tool in tool_installer_tools:
        tool_name = tool['name']
        dep_packages = tool.get('dependency_packages', {})

        # Check Debian packages
        debian_packages = dep_packages.get('Debian', [])
        for pkg in debian_packages:
            if not host.package(pkg).is_installed:
                failed_packages.append(f"{pkg} (for {tool_name})")

    if failed_packages:
        pytest.fail(
            f"The following dependency packages are not installed:\n" +
            "\n".join(f"  - {pkg}" for pkg in failed_packages)
        )


def test_tool_install_directories_exist(host, tool_installer_tools):
    """Verify tool installation directories exist."""
    if not tool_installer_tools:
        pytest.skip("No tool_installer tools configured")

    # Common installation directories
    install_dirs = [
        '/opt/tools',
        '$HOME/.local/tools',
    ]

    # At least one install directory should exist
    found = False
    for install_dir in install_dirs:
        cmd = host.run(f"test -d {install_dir}")
        if cmd.rc == 0:
            found = True
            break

    assert found, "No tool_installer installation directories found"


def test_tools_are_executable(host, tool_installer_tools):
    """Verify installed tools are executable."""
    if not tool_installer_tools:
        pytest.skip("No tool_installer tools configured")

    failed_tools = []

    for tool in tool_installer_tools:
        executables = tool.get('executables', [])

        for executable_config in executables:
            if isinstance(executable_config, dict):
                executable_name = executable_config.get('name')
            else:
                executable_name = executable_config

            if executable_name:
                # Find the executable
                cmd = host.run(f"which {executable_name}")
                if cmd.rc == 0:
                    executable_path = cmd.stdout.strip()

                    # Check if it's executable
                    cmd = host.run(f"test -x {executable_path}")
                    if cmd.rc != 0:
                        failed_tools.append(executable_name)

    if failed_tools:
        pytest.fail(
            f"The following tools are not executable:\n" +
            "\n".join(f"  - {tool}" for tool in failed_tools)
        )
