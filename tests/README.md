# Tests Directory

This directory contains testinfra-based tests for the Kali Linux VM template.

## Structure

```
tests/
├── conftest.py              # Pytest configuration and fixtures
├── pytest.ini               # Pytest settings
├── ansible_parser.py        # Ansible configuration parser
├── test_coverage.py         # Coverage enforcement tests
│
├── roles/                   # Role-specific tests (one per ansible role)
│   ├── test_common_pkgs.py
│   ├── test_docker.py
│   ├── test_neovim.py
│   └── ...
│
└── integration/             # System-wide integration tests
    ├── test_system.py
    ├── test_services.py
    └── ...
```

## Quick Start

```bash
# Install dependencies
pip install -r requirements-test.txt

# Run all tests against deployed VM
./scripts/kali_test.sh

# Run specific test category
pytest -m role              # Role tests only
pytest -m integration       # Integration tests only
pytest -m critical          # Critical tests only
```

## Key Features

✅ **Data-driven testing** - Tests read from Ansible configurations
✅ **No duplication** - Package lists defined once in Ansible
✅ **Coverage enforcement** - Fails if roles lack tests
✅ **Auto-updating** - Add package to Ansible → test updates automatically

## Example Usage

### Running Tests

```bash
# All tests
pytest -v

# Specific role
pytest tests/roles/test_docker.py

# With markers
pytest -m "role and not slow"

# Parallel execution
pytest -n auto
```

### Adding a New Package

**No test changes needed!** Just update Ansible:

```yaml
# ansible/vars/common_pkgs.yml
common_pkgs_apt:
  install:
    - new-package  # ← Add here, test auto-includes it
```

### Adding a New Role

1. Add role to `ansible/playbooks/provision.yml`
2. Create `tests/roles/test_newrole.py`:

```python
"""Tests for pluggero.newrole role."""
import pytest

def test_newrole_packages_installed(host, role_packages):
    """Verify packages from Ansible config are installed."""
    packages = role_packages('newrole')

    for pkg in packages:
        assert host.package(pkg).is_installed
```

## Available Fixtures

| Fixture | Description |
|---------|-------------|
| `host` | Testinfra host connection |
| `role_packages(name)` | Get packages for a role |
| `role_config(name)` | Get configuration for a role |
| `tool_installer_tools` | List of tool_installer tools |
| `python_tools` | List of python tools |

## Documentation

See [docs/TESTING.md](../docs/TESTING.md) for comprehensive testing guide.

## Troubleshooting

**Import Error**: Run from project root: `pytest tests/`

**No VM**: Tests require a deployed VM. Use `./scripts/kali_test.sh`

**Coverage Fails**: Create missing test files in `tests/roles/`
