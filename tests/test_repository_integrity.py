"""Offline integrity checks for the repository's installer assets."""
from __future__ import annotations

import py_compile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryIntegrityTests(unittest.TestCase):
    def test_required_installer_assets_exist(self) -> None:
        required = [
            "install.sh",
            "install.ps1",
            "config/CLAUDE.md",
            "setup/SKILL.md",
            "scripts/bash-guard.py",
            "scripts/health-check.sh",
            "scripts/init-memory.py",
            "scripts/memory-search.py",
            "scripts/scan-secrets.py",
            "scripts/update-state.py",
        ]
        missing = [path for path in required if not (ROOT / path).is_file()]
        self.assertEqual(missing, [], f"missing installer assets: {missing}")

    def test_python_hooks_compile(self) -> None:
        scripts = sorted((ROOT / "scripts").glob("*.py"))
        self.assertGreater(len(scripts), 0, "no Python hook scripts found")
        for script in scripts:
            py_compile.compile(str(script), doraise=True)

    def test_shell_scripts_use_lf(self) -> None:
        scripts = [ROOT / "install.sh", *sorted((ROOT / "scripts").glob("*.sh"))]
        for script in scripts:
            self.assertNotIn(b"\r\n", script.read_bytes(), f"CRLF breaks bash: {script}")


if __name__ == "__main__":
    unittest.main()