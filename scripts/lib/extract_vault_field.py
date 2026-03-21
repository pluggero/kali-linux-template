#!/usr/bin/env python3
"""Extract a field from an Ansible vault file."""
import sys
import subprocess
import yaml


def extract_vault_field(vault_file, vault_pass_file, field_name):
    """Extract a field from an Ansible vault file."""
    try:
        # Decrypt vault using ansible-vault
        result = subprocess.run(
            ['ansible-vault', 'view', vault_file, '--vault-password-file', vault_pass_file],
            capture_output=True,
            text=True,
            check=True
        )

        # Parse YAML
        vault_data = yaml.safe_load(result.stdout)

        if vault_data is None:
            print(f"ERROR: Vault file is empty or invalid: {vault_file}", file=sys.stderr)
            return None

        # Extract field
        value = vault_data.get(field_name)

        if value is None or value == '':
            print(f"ERROR: Field '{field_name}' not found or empty in vault file: {vault_file}", file=sys.stderr)
            print(f"       Please ensure the vault contains this field with a non-empty value.", file=sys.stderr)
            print(f"       Expected format: {field_name}: \"your-value-here\"", file=sys.stderr)
            return None

        # Convert to string if needed
        value = str(value)

        return value

    except subprocess.CalledProcessError as e:
        print(f"ERROR: Failed to decrypt vault file: {vault_file}", file=sys.stderr)
        print(f"       {e.stderr}", file=sys.stderr)
        return None
    except yaml.YAMLError as e:
        print(f"ERROR: Invalid YAML in vault file: {vault_file}", file=sys.stderr)
        print(f"       {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"ERROR: Unexpected error extracting field '{field_name}': {e}", file=sys.stderr)
        return None


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: extract_vault_field.py <vault_file> <vault_pass_file> <field_name>", file=sys.stderr)
        sys.exit(1)

    vault_file = sys.argv[1]
    vault_pass_file = sys.argv[2]
    field_name = sys.argv[3]

    value = extract_vault_field(vault_file, vault_pass_file, field_name)

    if value is None:
        sys.exit(1)

    print(value)
    sys.exit(0)
