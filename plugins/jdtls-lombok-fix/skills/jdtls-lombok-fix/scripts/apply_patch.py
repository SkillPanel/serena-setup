#!/usr/bin/env python3
"""Apply the Lombok javaagent workaround to the `jdtls-lsp` plugin.

Idempotent. Prints a single status line to stdout for the caller to parse:

  already-patched           — the patch is already in place
  patched: <path/to/jar>    — patch was just applied using that jar
  no-lombok-jar             — no usable Lombok jar found in ~/.m2
  marketplace-missing       — plugin or marketplace.json not found

Exit codes: 0 for success (including already-patched / marketplace-missing
 since both are "no action needed"); 1 when the user must intervene (no jar).

Background: https://github.com/anthropics/claude-plugins-official/issues/1000
"""
from __future__ import annotations

import json
import re
import shutil
import sys
import time
from pathlib import Path

HOME = Path.home()
MARKETPLACE = (
    HOME
    / ".claude"
    / "plugins"
    / "marketplaces"
    / "claude-plugins-official"
    / ".claude-plugin"
    / "marketplace.json"
)
LOMBOK_ROOT = HOME / ".m2" / "repository" / "org" / "projectlombok" / "lombok"


def _version_key(name: str) -> tuple[int, ...]:
    """Parse a version directory name like '1.18.44' into a sortable tuple."""
    nums = re.findall(r"\d+", name)
    return tuple(int(n) for n in nums) if nums else (0,)


def find_lombok_jar() -> Path | None:
    """Return the newest standalone Lombok jar available locally, or None."""
    if not LOMBOK_ROOT.is_dir():
        return None
    version_dirs = sorted(
        (p for p in LOMBOK_ROOT.iterdir() if p.is_dir()),
        key=lambda p: _version_key(p.name),
        reverse=True,
    )
    for vdir in version_dirs:
        for jar in vdir.glob("lombok-*.jar"):
            if "-sources" in jar.name or "-javadoc" in jar.name:
                continue
            return jar
    return None


def main() -> int:
    try:
        data = json.loads(MARKETPLACE.read_text())
    except FileNotFoundError:
        print("marketplace-missing")
        return 0
    except json.JSONDecodeError as exc:
        print(f"marketplace-invalid: {exc}")
        return 1

    plugin = next(
        (p for p in data.get("plugins", []) if p.get("name") == "jdtls-lsp"),
        None,
    )
    if plugin is None:
        print("marketplace-missing")
        return 0

    jdtls = plugin.get("lspServers", {}).get("jdtls")
    if jdtls is None:
        print("marketplace-missing")
        return 0

    args = list(jdtls.get("args") or [])
    already_patched = any(
        isinstance(a, str) and "-javaagent:" in a and "lombok" in a.lower()
        for a in args
    )
    if already_patched:
        print("already-patched")
        return 0

    jar = find_lombok_jar()
    if jar is None:
        print("no-lombok-jar")
        return 1

    backup = MARKETPLACE.parent / f"marketplace.json.bak-{int(time.time())}"
    shutil.copy2(MARKETPLACE, backup)

    args.append(f"--jvm-arg=-javaagent:{jar}")
    jdtls["args"] = args

    # Atomic write: tmp file + rename
    tmp = MARKETPLACE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n")
    tmp.replace(MARKETPLACE)

    print(f"patched: {jar}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
