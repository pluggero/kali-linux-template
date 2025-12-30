"""Tests for pluggero.bibata_cursor role."""
import pytest


def test_bibata_cursor_packages_installed(host, role_packages):
    """Verify Bibata cursor packages are installed."""
    packages = role_packages('bibata_cursor')
    if not packages:
        pytest.skip("No bibata_cursor packages configured")
    
    for pkg in packages:
        assert host.package(pkg).is_installed, f"Package '{pkg}' not installed"
