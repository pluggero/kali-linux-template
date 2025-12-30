"""
Ansible configuration parser for testinfra.

This module parses Ansible configurations (playbooks, vars, roles) to provide
a single source of truth for test data. This eliminates code duplication and
ensures tests stay synchronized with Ansible configurations.

Usage:
    from ansible_parser import AnsibleDataLoader

    loader = AnsibleDataLoader()
    packages = loader.get_role_packages('docker')
    config = loader.get_role_config('neovim')
    all_roles = loader.get_all_roles()
"""

import os
import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional, Set
from dataclasses import dataclass, field


@dataclass
class RoleData:
    """Data extracted from an Ansible role."""
    name: str
    packages: List[str] = field(default_factory=list)
    services: List[str] = field(default_factory=list)
    config: Dict[str, Any] = field(default_factory=dict)
    vars_files: List[str] = field(default_factory=list)


class AnsibleDataLoader:
    """Load and parse Ansible configurations for testing."""

    def __init__(self, base_path: Optional[str] = None):
        """
        Initialize the Ansible data loader.

        Args:
            base_path: Root directory of the project. Defaults to parent of tests/.
        """
        if base_path is None:
            # Assume this file is in tests/, so go up one level
            self.base_path = Path(__file__).parent.parent
        else:
            self.base_path = Path(base_path)

        self.ansible_path = self.base_path / "ansible"
        self.roles_path = self.ansible_path / "roles"
        self.vars_path = self.ansible_path / "vars"
        self.playbooks_path = self.ansible_path / "playbooks"

        # Cache for parsed data
        self._cache: Dict[str, Any] = {}
        self._roles_cache: Dict[str, RoleData] = {}

    def _load_yaml(self, file_path: Path) -> Any:
        """Load and parse a YAML file."""
        if not file_path.exists():
            return None

        try:
            with open(file_path, 'r') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Failed to load {file_path}: {e}")
            return None

    def get_all_roles(self) -> List[str]:
        """
        Get all roles defined in provision playbooks.

        Returns:
            List of role names (e.g., ['pluggero.docker', 'pluggero.neovim'])
        """
        cache_key = 'all_roles'
        if cache_key in self._cache:
            return self._cache[cache_key]

        roles = []

        # Parse provision-init.yml
        init_playbook = self.playbooks_path / "provision-init.yml"
        init_data = self._load_yaml(init_playbook)
        if init_data and isinstance(init_data, list):
            for play in init_data:
                if 'roles' in play:
                    roles.extend(play['roles'])

        # Parse provision.yml
        provision_playbook = self.playbooks_path / "provision.yml"
        provision_data = self._load_yaml(provision_playbook)
        if provision_data and isinstance(provision_data, list):
            for play in provision_data:
                if 'roles' in play:
                    roles.extend(play['roles'])

        # Deduplicate and sort
        roles = sorted(set(roles))

        self._cache[cache_key] = roles
        return roles

    def get_role_short_name(self, role_name: str) -> str:
        """
        Convert full role name to short name.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker')

        Returns:
            Short name (e.g., 'docker')
        """
        if '.' in role_name:
            return role_name.split('.', 1)[1]
        return role_name

    def get_role_vars_file(self, role_name: str) -> Optional[Path]:
        """
        Get the vars file path for a role.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker')

        Returns:
            Path to vars file or None
        """
        short_name = self.get_role_short_name(role_name)

        # Check in ansible/vars/{short_name}.yml
        vars_file = self.vars_path / f"{short_name}.yml"
        if vars_file.exists():
            return vars_file

        return None

    def get_role_defaults(self, role_name: str) -> Optional[Dict[str, Any]]:
        """
        Get role defaults from roles/{role}/defaults/main.yml.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker')

        Returns:
            Dictionary of defaults or None
        """
        role_path = self.roles_path / role_name
        defaults_file = role_path / "defaults" / "main.yml"

        return self._load_yaml(defaults_file)

    def get_role_vars(self, role_name: str, os_family: str = "Debian") -> Optional[Dict[str, Any]]:
        """
        Get role vars from roles/{role}/vars/{os_family}.yml.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker')
            os_family: OS family (e.g., 'Debian', 'Archlinux')

        Returns:
            Dictionary of vars or None
        """
        role_path = self.roles_path / role_name
        vars_file = role_path / "vars" / f"{os_family}.yml"

        return self._load_yaml(vars_file)

    def _extract_packages_from_dict(self, data: Dict[str, Any],
                                    known_package_keys: Set[str] = None) -> List[str]:
        """
        Extract package names from a configuration dictionary.

        Args:
            data: Dictionary potentially containing package lists
            known_package_keys: Known keys that contain package names

        Returns:
            List of package names
        """
        if known_package_keys is None:
            known_package_keys = {
                'install', 'packages', 'dep_pkgs', 'distro_pkgs',
                'dependency_packages', 'apt', 'apt_packages'
            }

        packages = []

        for key, value in data.items():
            # Check if key matches known package keys
            if any(pkg_key in key.lower() for pkg_key in known_package_keys):
                if isinstance(value, list):
                    for item in value:
                        if isinstance(item, str):
                            packages.append(item)
                        elif isinstance(item, dict) and 'name' in item:
                            packages.append(item['name'])
                elif isinstance(value, dict):
                    # Handle nested structures like common_pkgs_apt: {install: [...]}
                    packages.extend(self._extract_packages_from_dict(value, known_package_keys))

        return packages

    def get_role_packages(self, role_name: str) -> List[str]:
        """
        Get all packages installed by a role.

        This combines packages from:
        - ansible/vars/{role}.yml
        - roles/{role}/vars/Debian.yml (dep_pkgs, distro_pkgs)
        - roles/{role}/defaults/main.yml

        Args:
            role_name: Full role name (e.g., 'pluggero.docker') or short name

        Returns:
            List of package names
        """
        # Normalize to full role name
        if '.' not in role_name:
            role_name = f"pluggero.{role_name}"

        cache_key = f"packages_{role_name}"
        if cache_key in self._cache:
            return self._cache[cache_key]

        packages = []

        # Get from vars file
        vars_file = self.get_role_vars_file(role_name)
        if vars_file:
            vars_data = self._load_yaml(vars_file)
            if vars_data:
                packages.extend(self._extract_packages_from_dict(vars_data))

        # Get from role vars
        role_vars = self.get_role_vars(role_name)
        if role_vars:
            packages.extend(self._extract_packages_from_dict(role_vars))

        # Get from role defaults
        defaults = self.get_role_defaults(role_name)
        if defaults:
            packages.extend(self._extract_packages_from_dict(defaults))

        # Deduplicate and sort
        packages = sorted(set(packages))

        self._cache[cache_key] = packages
        return packages

    def get_role_config(self, role_name: str) -> Dict[str, Any]:
        """
        Get full configuration for a role.

        This merges data from vars, role vars, and defaults.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker') or short name

        Returns:
            Merged configuration dictionary
        """
        # Normalize to full role name
        if '.' not in role_name:
            role_name = f"pluggero.{role_name}"

        cache_key = f"config_{role_name}"
        if cache_key in self._cache:
            return self._cache[cache_key]

        config = {}

        # Merge defaults (lowest priority)
        defaults = self.get_role_defaults(role_name)
        if defaults:
            config.update(defaults)

        # Merge role vars (medium priority)
        role_vars = self.get_role_vars(role_name)
        if role_vars:
            config.update(role_vars)

        # Merge vars file (highest priority)
        vars_file = self.get_role_vars_file(role_name)
        if vars_file:
            vars_data = self._load_yaml(vars_file)
            if vars_data:
                config.update(vars_data)

        self._cache[cache_key] = config
        return config

    def get_tool_installer_tools(self) -> List[Dict[str, Any]]:
        """
        Get all tools from tool_installer configuration.

        Returns:
            List of tool configurations
        """
        cache_key = 'tool_installer_tools'
        if cache_key in self._cache:
            return self._cache[cache_key]

        vars_file = self.vars_path / "tool_installer.yml"
        data = self._load_yaml(vars_file)

        tools = []
        if data and 'tool_installer_tools' in data:
            tools = data['tool_installer_tools']

        self._cache[cache_key] = tools
        return tools

    def get_python_tools(self) -> List[Dict[str, Any]]:
        """
        Get all Python tools from python role configuration.

        Returns:
            List of Python tool configurations
        """
        cache_key = 'python_tools'
        if cache_key in self._cache:
            return self._cache[cache_key]

        vars_file = self.vars_path / "python.yml"
        data = self._load_yaml(vars_file)

        tools = []
        if data and 'python_tools' in data:
            tools = data['python_tools']

        self._cache[cache_key] = tools
        return tools

    def get_role_data(self, role_name: str) -> RoleData:
        """
        Get comprehensive data for a role.

        Args:
            role_name: Full role name (e.g., 'pluggero.docker') or short name

        Returns:
            RoleData object with packages, services, config, etc.
        """
        # Normalize to full role name
        if '.' not in role_name:
            role_name = f"pluggero.{role_name}"

        if role_name in self._roles_cache:
            return self._roles_cache[role_name]

        role_data = RoleData(
            name=role_name,
            packages=self.get_role_packages(role_name),
            config=self.get_role_config(role_name)
        )

        # Extract services from config if present
        config = role_data.config
        for key in config.keys():
            if 'service' in key.lower() and isinstance(config[key], str):
                role_data.services.append(config[key])

        self._roles_cache[role_name] = role_data
        return role_data
