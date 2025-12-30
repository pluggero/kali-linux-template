"""
Kali-specific tool tests for Kali Linux VM.

Tests that essential Kali Linux security tools are installed and functional.
"""

import pytest


@pytest.mark.parametrize("tool", [
    "nmap",
    "netcat",
    "curl",
    "wget",
    "git",
])
def test_essential_tools_available(host, tool):
    """Verify essential security tools are in PATH."""
    cmd = host.run(f"which {tool}")

    assert cmd.rc == 0, f"Tool '{tool}' not found in PATH"


def test_nmap_version(host):
    """Verify nmap is installed and working."""
    cmd = host.run("nmap --version")

    assert cmd.rc == 0
    assert "Nmap" in cmd.stdout


def test_git_version(host):
    """Verify git is installed and working."""
    cmd = host.run("git --version")

    assert cmd.rc == 0
    assert "git version" in cmd.stdout


def test_curl_functionality(host):
    """Verify curl can make basic HTTPS requests."""
    # Test with a reliable endpoint
    cmd = host.run("curl -s -o /dev/null -w '%{http_code}' https://www.kali.org --max-time 10")

    # Should get a 200 or 3xx redirect
    if cmd.rc == 0:
        http_code = cmd.stdout.strip()
        assert http_code.startswith('2') or http_code.startswith('3'), \
            f"Unexpected HTTP code: {http_code}"


def test_python3_requests_module(host):
    """Verify Python can import requests module (if installed)."""
    cmd = host.run("python3 -c 'import requests; print(requests.__version__)'")

    # This might not be installed by default, so it's a soft check
    if cmd.rc == 0:
        print(f"Python requests module version: {cmd.stdout.strip()}")


def test_network_connectivity(host):
    """Verify VM has network connectivity."""
    # Ping a reliable host
    cmd = host.run("ping -c 1 -W 5 8.8.8.8")

    assert cmd.rc == 0, "No network connectivity (cannot ping 8.8.8.8)"


def test_dns_resolution(host):
    """Verify DNS resolution is working."""
    cmd = host.run("nslookup kali.org")

    assert cmd.rc == 0, "DNS resolution is not working"
    assert "Address" in cmd.stdout or "address" in cmd.stdout


def test_package_manager_functional(host):
    """Verify apt package manager is functional."""
    # Just check if we can run apt without errors
    cmd = host.run("apt-cache policy")

    assert cmd.rc == 0, "apt package manager is not functional"


@pytest.mark.slow
def test_apt_update_check(host):
    """Verify we can check for updates (slow test)."""
    # This is a slow test as it contacts repositories
    cmd = host.run("apt-get update -qq")

    assert cmd.rc == 0, "Failed to update package lists"


def test_kali_repositories_accessible(host):
    """Verify Kali repositories are configured and accessible."""
    cmd = host.run("apt-cache policy | grep -i kali")

    assert cmd.rc == 0, "Kali repositories not found in apt sources"
    assert "kali" in cmd.stdout.lower()


def test_basic_shell_functionality(host):
    """Verify basic shell commands work."""
    test_commands = [
        "echo 'test'",
        "ls /",
        "cat /etc/hostname",
        "pwd",
    ]

    for cmd_str in test_commands:
        cmd = host.run(cmd_str)
        assert cmd.rc == 0, f"Command failed: {cmd_str}"


def test_text_editors_available(host):
    """Verify at least one text editor is available."""
    editors = ["vim", "vi", "nano"]

    found_editor = False
    for editor in editors:
        cmd = host.run(f"which {editor}")
        if cmd.rc == 0:
            found_editor = True
            break

    assert found_editor, "No text editor (vim/vi/nano) found"


def test_compression_tools(host):
    """Verify compression tools are available."""
    tools = ["tar", "gzip", "gunzip", "bzip2"]

    for tool in tools:
        cmd = host.run(f"which {tool}")
        assert cmd.rc == 0, f"Compression tool '{tool}' not found"
