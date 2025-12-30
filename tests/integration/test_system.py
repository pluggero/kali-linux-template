"""
System-level tests for Kali Linux VM.

Tests basic system functionality including OS version, kernel, hostname,
and essential system commands.
"""

import pytest


@pytest.mark.critical
def test_os_release(host):
    """Verify OS is Kali Linux."""
    os_release = host.file("/etc/os-release")

    assert os_release.exists
    assert os_release.contains("ID=kali")
    assert os_release.contains("NAME=\"Kali GNU/Linux\"")


@pytest.mark.critical
def test_kernel_version(host):
    """Verify kernel is running."""
    cmd = host.run("uname -r")

    assert cmd.rc == 0
    assert len(cmd.stdout.strip()) > 0
    # Kali typically uses a kernel with 'kali' in the version
    # but this may vary, so just check it's a valid kernel string
    assert "-" in cmd.stdout


def test_hostname(host):
    """Verify hostname is set."""
    cmd = host.run("hostname")

    assert cmd.rc == 0
    assert len(cmd.stdout.strip()) > 0


def test_system_uptime(host):
    """Verify system is up and running."""
    cmd = host.run("uptime")

    assert cmd.rc == 0
    assert "load average" in cmd.stdout.lower()


def test_disk_space(host):
    """Verify sufficient disk space is available."""
    cmd = host.run("df -h /")

    assert cmd.rc == 0
    # Extract usage percentage for root filesystem
    lines = cmd.stdout.strip().split('\n')
    if len(lines) >= 2:
        # Parse the usage percentage (e.g., "45%")
        usage = lines[1].split()[4].rstrip('%')
        assert int(usage) < 95, f"Root filesystem is {usage}% full"


def test_memory_info(host):
    """Verify system memory information is accessible."""
    meminfo = host.file("/proc/meminfo")

    assert meminfo.exists
    assert meminfo.contains("MemTotal")


def test_cpu_info(host):
    """Verify CPU information is accessible."""
    cpuinfo = host.file("/proc/cpuinfo")

    assert cpuinfo.exists
    assert cpuinfo.contains("processor")


def test_timezone(host):
    """Verify timezone is configured."""
    cmd = host.run("timedatectl show -p Timezone --value")

    assert cmd.rc == 0
    assert len(cmd.stdout.strip()) > 0


def test_locale(host):
    """Verify locale is configured."""
    cmd = host.run("locale")

    assert cmd.rc == 0
    assert "LANG=" in cmd.stdout


@pytest.mark.critical
def test_apt_sources(host):
    """Verify APT sources are configured."""
    sources_list = host.file("/etc/apt/sources.list")

    assert sources_list.exists
    # Kali should have kali.org in sources
    cmd = host.run("grep -r 'kali.org' /etc/apt/sources.list.d/ /etc/apt/sources.list")
    assert cmd.rc == 0


def test_system_commands(host):
    """Verify essential system commands are available."""
    essential_commands = [
        'bash',
        'sh',
        'ls',
        'cat',
        'grep',
        'awk',
        'sed',
        'find',
        'which',
        'sudo',
    ]

    for cmd in essential_commands:
        result = host.run(f"which {cmd}")
        assert result.rc == 0, f"Command '{cmd}' not found in PATH"
