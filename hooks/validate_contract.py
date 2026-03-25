#!/usr/bin/env python3
"""
Claude Code native hook: validates PEV loop contract files for required ID tags.

Triggered automatically via PostToolUse on Write and Edit tool calls.
Reads hook context from stdin (JSON), detects the PEV role from the filename,
and validates that required ID tags are present.

ID tag requirements:
  PLANNER   -> each invariant/constraint tagged [INV_001], [INV_002], ...
  EXECUTOR  -> each output item tagged [EXEC_001], [EXEC_002], ...
  VERIFIER  -> each success criterion tagged [SUC_001], [SUC_002], ...
"""

import json
import sys
import os
import re

PATTERNS = {
    "PLANNER": r"\[INV_\w+\]",
    "EXECUTOR": r"\[EXEC_\w+\]",
    "VERIFIER": r"\[SUC_\w+\]",
}


def get_role(filepath: str):
    """Detect PEV role from contract filename. Returns None if not a PEV contract."""
    name = os.path.basename(filepath).upper()

    if "PLANNER_TO_EXECUTION" in name or "PLAN_ATTEMPT" in name:
        return "PLANNER"

    if "EXECUTION_TO_VERIFIER" in name or "IMPLEMENTATION_ATTEMPT" in name:
        return "EXECUTOR"

    if "VERIFIER" in name or "VERIFICATION_ATTEMPT" in name:
        return "VERIFIER"

    return None


def is_pev_contract(filepath: str) -> bool:
    """Check if file is a PEV loop artifact that should be validated."""
    parts = filepath.replace("\\", "/").split("/")
    name = os.path.basename(filepath).upper()
    in_contracts = "contracts" in parts
    in_markdown = "markdown" in parts
    has_attempt = "ATTEMPT_" in name
    return (in_contracts or in_markdown) and has_attempt


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_input = data.get("tool_input", {})
    filepath = tool_input.get("file_path", "")

    if not filepath or not is_pev_contract(filepath):
        sys.exit(0)

    role = get_role(filepath)
    if not role:
        sys.exit(0)

    if not os.path.exists(filepath):
        sys.exit(0)

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    matches = re.findall(PATTERNS[role], content)

    if not matches:
        os.makedirs("contracts", exist_ok=True)
        nudge_path = os.path.join("contracts", "NUDGE.md")
        with open(nudge_path, "w", encoding="utf-8") as f:
            f.write(
                f"# NUDGE\n"
                f"{role} failed to output required ID tags in `{filepath}`.\n\n"
                f"Every item must be prefixed with its ID tag:\n"
                f"- PLANNER invariants/constraints: `[INV_001]`, `[INV_002]`, ...\n"
                f"- EXECUTOR output items: `[EXEC_001]`, `[EXEC_002]`, ...\n"
                f"- VERIFIER success criteria: `[SUC_001]`, `[SUC_002]`, ...\n\n"
                f"Rewrite the contract file with proper ID-tagged items and save again."
            )
        print(f"[HOOK FAIL] {role} contract is missing required ID tags: {filepath}")
        print(f"Expected pattern: {PATTERNS[role]}")
        print("Rewrite the contract with ID-tagged items. See contracts/NUDGE.md for details.")
        sys.exit(2)

    print(f"[HOOK PASS] {role} contract validated — {len(matches)} ID tag(s) found in {os.path.basename(filepath)}")

    os.makedirs("contracts", exist_ok=True)
    validated_path = os.path.join("contracts", f"{role}_VALIDATED.md")
    with open(validated_path, "w", encoding="utf-8") as f:
        f.write(f"# VALIDATED\n{role} outputs for `{filepath}` validated by Claude Code hook.")

    sys.exit(0)


if __name__ == "__main__":
    main()
