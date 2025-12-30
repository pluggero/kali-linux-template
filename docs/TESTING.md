# Testing Guide

This document describes the testing infrastructure for the Kali Linux template project.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Test Organization](#test-organization)
- [Running Tests](#running-tests)
- [Adding New Tests](#adding-new-tests)
- [Coverage Enforcement](#coverage-enforcement)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The testing system uses **testinfra** (built on pytest) to validate deployed VMs. The key innovation is **data-driven testing** that reads Ansible configurations as the single source of truth.

### Key Features

✅ **No code duplication** - Package lists defined once in Ansible
✅ **Automatic test generation** - Tests use Ansible data via fixtures
✅ **Coverage enforcement** - Fails if roles lack tests
✅ **Easy maintenance** - Add a package to Ansible, test auto-updates
✅ **Clear organization** - Role-based and integration tests separated

### Testing Philosophy

1. **Single source of truth**: Ansible configurations define what should be installed
2. **Fail fast**: Tests fail if changes are made without corresponding test updates
3. **Data-driven**: Tests parametrize over Ansible data automatically
4. **Comprehensive**: Both role-specific and integration tests

---

## Architecture

```
tests/
├── conftest.py                 # Pytest configuration & fixtures
├── pytest.ini                  # Pytest settings
├── ansible_parser.py           # Parses ansible configs (SINGLE SOURCE OF TRUTH)
├── test_coverage.py            # Enforces that all roles have tests
│
├── roles/                      # Role-specific tests (one per ansible role)
│   ├── test_common_pkgs.py
│   ├── test_docker.py
│   ├── test_neovim.py
│   ├── test_python.py
│   ├── test_tool_installer.py
│   └── ...                     # 24 role test files total
│
└── integration/                # System-wide integration tests
    ├── test_system.py          # OS, kernel, basic functionality
    ├── test_services.py        # System services
    ├── test_security.py        # Security hardening
    ├── test_users.py           # User accounts
    ├── test_kali_tools.py      # Kali-specific tools
    └── test_packages.py        # Package manager health
```

### Components

#### 1. `ansible_parser.py`
Parses Ansible configurations to extract:
- Roles from `provision*.yml` playbooks
- Packages from vars files and role definitions
- Tool configurations (tool_installer, python_tools)
- Service configurations

**API**:
```python
from ansible_parser import AnsibleDataLoader

loader = AnsibleDataLoader()
roles = loader.get_all_roles()              # ['pluggero.docker', ...]
packages = loader.get_role_packages('docker')  # ['docker-ce', ...]
config = loader.get_role_config('neovim')   # {neovim_version: '0.11.5', ...}
tools = loader.get_tool_installer_tools()   # [{name: 'jwt_tool', ...}, ...]
```

#### 2. `conftest.py`
Provides pytest fixtures for accessing Ansible data:

```python
# Available fixtures:
ansible_data         # AnsibleDataLoader instance
installed_roles      # List of all roles from playbooks
role_packages(name)  # Get packages for a role
role_config(name)    # Get config for a role
role_data(name)      # Get comprehensive role data
tool_installer_tools # List of tool_installer tools
python_tools         # List of python_tools
```

#### 3. `test_coverage.py`
Enforces testing coverage:
- ✅ Ensures every role has a test file
- ✅ Detects orphaned test files
- ✅ Validates test file syntax
- ❌ **FAILS** if coverage is incomplete

---

## Test Organization

### Role-Specific Tests (`tests/roles/`)

Each Ansible role has a corresponding test file. Tests use Ansible data fixtures to avoid hardcoding.

**Example**: `tests/roles/test_docker.py`
```python
import pytest

def test_docker_packages_installed(host, role_packages):
    """Verify all Docker packages from Ansible config are installed."""
    packages = role_packages('docker')  # Reads from ansible/vars/docker.yml

    for pkg in packages:
        assert host.package(pkg).is_installed

def test_docker_service_configured(host, role_config):
    """Verify Docker service based on Ansible configuration."""
    config = role_config('docker')

    if config.get('docker_service_enabled', False):
        assert host.service('docker').is_enabled
        assert host.service('docker').is_running
```

### Integration Tests (`tests/integration/`)

System-wide tests that validate overall functionality:

- **test_system.py** - OS version, kernel, basic commands
- **test_services.py** - SSH, systemd, networking services
- **test_security.py** - Security hardening, firewall rules
- **test_users.py** - User accounts, permissions, groups
- **test_kali_tools.py** - Kali-specific tools and utilities
- **test_packages.py** - Package manager health, no broken packages

---

## Running Tests

### Prerequisites

```bash
# Install test dependencies
pip install -r requirements-test.txt
```

### Basic Test Execution

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/roles/test_docker.py

# Run specific test
pytest tests/roles/test_docker.py::test_docker_packages_installed
```

### Test Markers

Tests are automatically tagged with markers:

```bash
# Run only role-specific tests
pytest -m role

# Run only integration tests
pytest -m integration

# Run only critical tests
pytest -m critical

# Run everything except slow tests
pytest -m "not slow"

# Combine markers
pytest -m "role and not slow"
```

### Using the Test Script

```bash
# Test the latest build
./scripts/kali_test.sh

# Test specific box file
./scripts/kali_test.sh true true /path/to/box.box

# Keep VM running after tests (for debugging)
./scripts/kali_test.sh false false
```

### Parallel Execution

```bash
# Run tests in parallel (4 workers)
pytest -n 4

# Auto-detect CPU count
pytest -n auto
```

### Coverage Reports

```bash
# Run with coverage
pytest --cov=tests --cov-report=html

# View coverage report
open htmlcov/index.html
```

---

## Adding New Tests

### When Adding a New Ansible Role

1. **Add the role to a playbook** (`ansible/playbooks/provision.yml`)
2. **Create the role's vars file** (`ansible/vars/{role}.yml`)
3. **Create the test file** (`tests/roles/test_{role}.py`)

**Example**: Adding `test_newrole.py`

```python
"""Tests for pluggero.newrole role."""
import pytest


def test_newrole_packages_installed(host, role_packages):
    """Verify newrole packages are installed."""
    packages = role_packages('newrole')  # Automatically reads from ansible

    if not packages:
        pytest.skip("No newrole packages configured")

    for pkg in packages:
        assert host.package(pkg).is_installed


def test_newrole_service(host, role_config):
    """Verify newrole service if applicable."""
    config = role_config('newrole')

    # Use config to determine what to test
    if config.get('newrole_service_enabled'):
        assert host.service('newrole').is_running
```

### When Adding Packages to an Existing Role

**No test changes needed!** Just update the Ansible vars file:

```yaml
# ansible/vars/common_pkgs.yml
common_pkgs_apt:
  install:
    - existing-package
    - new-package  # <-- Add here
```

The test will automatically include it:
```python
def test_common_packages_from_ansible(host, role_packages):
    packages = role_packages('common_pkgs')  # Includes new-package
    for pkg in packages:
        assert host.package(pkg).is_installed
```

### When Adding Tools via tool_installer

**No test changes needed!** Just update the config:

```yaml
# ansible/vars/tool_installer.yml
tool_installer_tools:
  - name: "new_tool"
    url: "https://github.com/example/new_tool"
    executables:
      - name: "new_tool"
```

The test automatically picks it up:
```python
def test_tool_installer_tools_from_ansible(host, tool_installer_tools):
    for tool in tool_installer_tools:  # Includes new_tool
        for exe in tool['executables']:
            assert host.run(f"which {exe['name']}").rc == 0
```

---

## Coverage Enforcement

### How It Works

`test_coverage.py` automatically:

1. **Discovers all roles** from `provision*.yml` playbooks
2. **Checks** that `tests/roles/test_{role}.py` exists for each
3. **FAILS** with a clear message if any are missing

### When Coverage Fails

```
COVERAGE FAILURE: 2 role(s) missing tests
======================================================================

The following roles do not have test files:

  - pluggero.newrole
    Expected: tests/roles/test_newrole.py

  - pluggero.anotherrole
    Expected: tests/roles/test_anotherrole.py

======================================================================
To fix this:
  1. Create test files for the missing roles in tests/roles/
  2. Use the ansible data fixtures to avoid code duplication
  3. See tests/roles/test_docker.py for an example
======================================================================
```

---

## Best Practices

### DO ✅

- **Use ansible data fixtures** - Avoid hardcoding package lists
- **Test role behavior, not implementation** - Focus on outcomes
- **Use descriptive test names** - `test_docker_service_enabled_when_configured`
- **Group related assertions** - Fail with helpful error messages
- **Mark critical tests** - Use `@pytest.mark.critical` for must-pass tests
- **Document unusual tests** - Add comments explaining why

### DON'T ❌

- **Hardcode package names** - Use `role_packages()` fixture
- **Duplicate Ansible config** - Single source of truth in Ansible
- **Test Ansible itself** - Trust that Ansible works correctly
- **Ignore coverage failures** - Fix them immediately
- **Write brittle tests** - Make them resilient to minor changes

### Example: Good vs Bad

**❌ Bad** (hardcoded):
```python
def test_docker_installed(host):
    assert host.package('docker-ce').is_installed
    assert host.package('docker-ce-cli').is_installed
    assert host.package('containerd.io').is_installed
```

**✅ Good** (data-driven):
```python
def test_docker_packages_installed(host, role_packages):
    """Verify all Docker packages from Ansible config are installed."""
    packages = role_packages('docker')

    failed = [pkg for pkg in packages if not host.package(pkg).is_installed]

    if failed:
        pytest.fail(f"Missing packages:\n" + "\n".join(f"  - {p}" for p in failed))
```

---

## Troubleshooting

### Tests Fail with "KALI_VM_IP not set"

The tests expect to run against a deployed VM. Use the test script:

```bash
./scripts/kali_test.sh
```

Or set environment variables manually:
```bash
export KALI_VM_IP="192.168.1.100"
export KALI_SSH_USER="kali"
pytest
```

### Coverage Test Fails After Adding Role

1. Check role is in `ansible/playbooks/provision.yml` or `provision-init.yml`
2. Create `tests/roles/test_{role_name}.py`
3. Use the template from [Adding New Tests](#adding-new-tests)

### Ansible Parser Can't Find Packages

The parser looks in these locations (in order):
1. `ansible/vars/{role_short_name}.yml`
2. `ansible/roles/{role_name}/vars/Debian.yml`
3. `ansible/roles/{role_name}/defaults/main.yml`

Ensure packages are defined in one of these files with standard keys:
- `install`, `packages`
- `dep_pkgs`, `distro_pkgs`
- `dependency_packages`

### Tests Pass Locally But Fail in CI

- **Different VM state**: Ensure tests don't depend on previous test runs
- **Timing issues**: Add appropriate waits for services
- **SSH issues**: Check SSH keys and permissions
- **Network dependencies**: Mock or skip network-dependent tests in CI

---

## Reference

### Available Pytest Fixtures

| Fixture | Scope | Description |
|---------|-------|-------------|
| `host` | session | Testinfra host connection |
| `ansible_data` | session | AnsibleDataLoader instance |
| `installed_roles` | session | List of all installed roles |
| `role_packages` | function | Get packages for a role |
| `role_config` | function | Get config for a role |
| `role_data` | function | Get comprehensive role data |
| `tool_installer_tools` | session | List of tool_installer tools |
| `python_tools` | session | List of python_tools |

### Useful Pytest Options

| Option | Description |
|--------|-------------|
| `-v` | Verbose output |
| `-vv` | Very verbose output |
| `-s` | Show print statements |
| `-x` | Stop on first failure |
| `-k EXPR` | Run tests matching expression |
| `-m MARKER` | Run tests with marker |
| `-n NUM` | Run in parallel with NUM workers |
| `--lf` | Run last failed tests |
| `--ff` | Run failures first, then rest |
| `--pdb` | Drop to debugger on failure |

---

## Resources

- [Testinfra Documentation](https://testinfra.readthedocs.io/)
- [Pytest Documentation](https://docs.pytest.org/)
- [Main Project README](../README.md)

---

**Questions or issues?** Open an issue on GitHub or check the troubleshooting section above.
