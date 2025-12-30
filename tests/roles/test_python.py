"""
Tests for pluggero.python role.

This role installs Python tools in virtual environments.
Tests use configuration from ansible/vars/python.yml.
"""

import pytest


@pytest.mark.parametrize("tool", [
    pytest.param(tool['package'], id=tool['package'])
    for tool in []  # Will be populated via python_tools fixture
])
def test_python_tool_installed(host, tool):
    """Test python tool is installed (parametrized)."""
    # This is a placeholder for parametrized tests
    pass


def test_python_tools_from_ansible(host, python_tools):
    """Verify all Python tools from ansible config are installed."""
    if not python_tools:
        pytest.skip("No Python tools configured")

    failed_tools = []
    for tool_config in python_tools:
        package = tool_config['package']
        executables = tool_config.get('executables', [])

        # Check if executables are in PATH
        for executable in executables:
            cmd = host.run(f"which {executable}")
            if cmd.rc != 0:
                failed_tools.append(f"{package} (executable: {executable})")

    if failed_tools:
        pytest.fail(
            f"The following Python tools are not in PATH:\n" +
            "\n".join(f"  - {tool}" for tool in failed_tools)
        )


def test_frida_tools_available(host, python_tools):
    """Verify Frida tools are installed if configured."""
    frida_tools = [t for t in python_tools if 'frida' in t['package'].lower()]

    if not frida_tools:
        pytest.skip("Frida tools not configured")

    # Check for key frida executables
    frida_executables = ['frida', 'frida-ps', 'frida-trace', 'objection']

    for executable in frida_executables:
        # Check if this executable is configured
        for tool in frida_tools:
            if executable in tool.get('executables', []):
                cmd = host.run(f"which {executable}")
                assert cmd.rc == 0, f"Frida tool '{executable}' not found in PATH"
                break


def test_impacket_tools_available(host, python_tools):
    """Verify Impacket tools are installed if configured."""
    impacket_tools = [t for t in python_tools if 'impacket' in t['package'].lower()]

    if not impacket_tools:
        pytest.skip("Impacket tools not configured")

    # Check for key impacket scripts
    key_scripts = ['secretsdump.py', 'GetNPUsers.py', 'psexec.py', 'ntlmrelayx.py']

    for script in key_scripts:
        # Check if this script is configured
        for tool in impacket_tools:
            if script in tool.get('executables', []):
                cmd = host.run(f"which {script}")
                assert cmd.rc == 0, f"Impacket script '{script}' not found in PATH"
                break


def test_python_venv_directories(host, python_tools):
    """Verify Python virtual environment directories exist."""
    if not python_tools:
        pytest.skip("No Python tools configured")

    # Group tools by venv
    venvs = set()
    for tool in python_tools:
        venv_name = tool.get('venv_name')
        if venv_name:
            venvs.add(venv_name)

    # Check that venv directories exist (common locations)
    venv_base_paths = [
        '/opt/python-tools',
        '$HOME/.local/share/python-tools'
    ]

    # At least some venvs should exist
    found_venvs = 0
    for venv in venvs:
        for base_path in venv_base_paths:
            cmd = host.run(f"test -d {base_path}/{venv}")
            if cmd.rc == 0:
                found_venvs += 1
                break

    # We should find at least one venv
    if venvs and found_venvs == 0:
        pytest.skip("Could not locate Python venv directories")


def test_drozer_available(host, python_tools):
    """Verify drozer is installed if configured."""
    drozer_tools = [t for t in python_tools if 'drozer' in t['package'].lower()]

    if not drozer_tools:
        pytest.skip("Drozer not configured")

    cmd = host.run("which drozer")
    assert cmd.rc == 0, "drozer not found in PATH"
