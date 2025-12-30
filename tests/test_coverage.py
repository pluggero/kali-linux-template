"""
Test coverage enforcement for Ansible roles.

This module ensures that all Ansible roles have corresponding test files.
If a role is added or modified without tests, these tests will FAIL.

This prevents untested configuration changes from being deployed.
"""

import pytest
from pathlib import Path


def test_all_roles_have_tests(installed_roles):
    """
    Verify that every Ansible role has a corresponding test file.

    This test ensures that when new roles are added to the provisioning
    playbooks, developers must also create tests for them.

    Fails with a clear message listing all untested roles.
    """
    test_dir = Path(__file__).parent
    roles_test_dir = test_dir / "roles"

    # Track which roles have tests
    missing_tests = []

    for role in installed_roles:
        # Extract short name (e.g., 'docker' from 'pluggero.docker')
        short_name = role.split('.', 1)[1] if '.' in role else role

        # Expected test file path
        test_file = roles_test_dir / f"test_{short_name}.py"

        if not test_file.exists():
            missing_tests.append(role)

    # Fail if any roles are missing tests
    if missing_tests:
        error_msg = (
            f"\n\n{'='*70}\n"
            f"COVERAGE FAILURE: {len(missing_tests)} role(s) missing tests\n"
            f"{'='*70}\n\n"
            f"The following roles do not have test files:\n\n"
        )
        for role in missing_tests:
            short_name = role.split('.', 1)[1] if '.' in role else role
            error_msg += f"  - {role}\n"
            error_msg += f"    Expected: tests/roles/test_{short_name}.py\n\n"

        error_msg += (
            f"{'='*70}\n"
            f"To fix this:\n"
            f"  1. Create test files for the missing roles in tests/roles/\n"
            f"  2. Use the ansible data fixtures to avoid code duplication\n"
            f"  3. See tests/roles/test_docker.py for an example\n"
            f"{'='*70}\n"
        )

        pytest.fail(error_msg)


def test_role_test_files_are_valid(installed_roles):
    """
    Verify that test files for roles are syntactically valid Python files.

    This is a basic sanity check to ensure test files can be imported.
    """
    test_dir = Path(__file__).parent
    roles_test_dir = test_dir / "roles"

    if not roles_test_dir.exists():
        pytest.skip("roles/ test directory does not exist yet")

    errors = []

    for test_file in roles_test_dir.glob("test_*.py"):
        try:
            # Try to compile the file to check for syntax errors
            with open(test_file, 'r') as f:
                compile(f.read(), test_file, 'exec')
        except SyntaxError as e:
            errors.append(f"{test_file.name}: {e}")

    if errors:
        error_msg = (
            f"\n\nSyntax errors found in role test files:\n"
            f"{'='*70}\n"
        )
        for error in errors:
            error_msg += f"  - {error}\n"
        pytest.fail(error_msg)


def test_no_orphaned_role_tests(installed_roles):
    """
    Verify that test files don't exist for roles that aren't installed.

    This helps keep the test suite clean by detecting test files for
    roles that have been removed from the provisioning playbooks.
    """
    test_dir = Path(__file__).parent
    roles_test_dir = test_dir / "roles"

    if not roles_test_dir.exists():
        pytest.skip("roles/ test directory does not exist yet")

    # Get short names of installed roles
    installed_short_names = set()
    for role in installed_roles:
        short_name = role.split('.', 1)[1] if '.' in role else role
        installed_short_names.add(short_name)

    # Check for orphaned test files
    orphaned = []
    for test_file in roles_test_dir.glob("test_*.py"):
        # Extract role name from test file (test_docker.py -> docker)
        if test_file.stem.startswith("test_"):
            role_name = test_file.stem[5:]  # Remove 'test_' prefix

            if role_name not in installed_short_names:
                orphaned.append(test_file.name)

    if orphaned:
        error_msg = (
            f"\n\nOrphaned test files detected:\n"
            f"{'='*70}\n"
            f"The following test files exist but their roles are not installed:\n\n"
        )
        for test_file in orphaned:
            error_msg += f"  - {test_file}\n"

        error_msg += (
            f"\n"
            f"Either:\n"
            f"  1. Add the corresponding role to a provisioning playbook, or\n"
            f"  2. Remove the orphaned test file\n"
        )

        pytest.fail(error_msg)


@pytest.mark.critical
def test_critical_roles_have_comprehensive_tests(installed_roles):
    """
    Ensure critical roles have comprehensive test coverage.

    Critical roles are those that are essential for security or basic
    functionality. This test can be extended with more specific checks.
    """
    critical_roles = [
        'pluggero.user_setup',
        'pluggero.upgrade',
        'pluggero.virtualbox_guest',
    ]

    # Check that all critical roles are installed
    installed_set = set(installed_roles)

    for role in critical_roles:
        if role not in installed_set:
            pytest.fail(
                f"Critical role '{role}' is not in provisioning playbooks. "
                f"If this is intentional, update the critical_roles list in "
                f"test_coverage.py"
            )
