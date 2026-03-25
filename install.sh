#!/bin/sh
# install.sh — Install the nen-contract PEV plugin globally for Claude Code
# Run from the nen-contract-plugin/ directory: chmod +x install.sh && ./install.sh

set -e

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing nen-contract PEV plugin..."

# 1. Create ~/.claude/commands/ if needed
mkdir -p "$HOME/.claude/commands"
echo "[1/5] Created ~/.claude/commands/ (if not present)"

# 2. Copy command files
cp "$PLUGIN_DIR/commands/nen-contract.md" "$HOME/.claude/commands/nen-contract.md"
echo "[2/5] Copied commands/nen-contract.md -> ~/.claude/commands/nen-contract.md"

cp "$PLUGIN_DIR/commands/pev-loop-human-handoff-v2.md" "$HOME/.claude/commands/pev-loop-human-handoff-v2.md"
echo "[2/5] Copied commands/pev-loop-human-handoff-v2.md -> ~/.claude/commands/pev-loop-human-handoff-v2.md"

# 3. Create ~/.claude/hooks/ if needed
mkdir -p "$HOME/.claude/hooks"
echo "[3/5] Created ~/.claude/hooks/ (if not present)"

# 4. Copy hook script
cp "$PLUGIN_DIR/hooks/validate_contract.py" "$HOME/.claude/hooks/validate_contract.py"
echo "[4/5] Copied hooks/validate_contract.py -> ~/.claude/hooks/validate_contract.py"

# 5. Patch ~/.claude/settings.json
echo "[5/5] Patching ~/.claude/settings.json..."
python3 - <<'PYEOF'
import json, os, shutil, tempfile

settings_path = os.path.expanduser("~/.claude/settings.json")
data = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        data = json.load(f)

hooks = data.setdefault("hooks", {})
post = hooks.setdefault("PostToolUse", [])

NEN_CMD = "python ~/.claude/hooks/validate_contract.py"

for matcher in ("Write", "Edit"):
    entry = next((e for e in post if e.get("matcher") == matcher), None)
    if entry is None:
        entry = {"matcher": matcher, "hooks": []}
        post.append(entry)
    existing_cmds = [h.get("command") for h in entry.get("hooks", [])]
    if NEN_CMD not in existing_cmds:
        entry["hooks"].append({"type": "command", "command": NEN_CMD})

dir_ = os.path.dirname(settings_path) or "."
with tempfile.NamedTemporaryFile("w", dir=dir_, delete=False, suffix=".tmp") as tmp:
    json.dump(data, tmp, indent=2)
    tmp_path = tmp.name
shutil.move(tmp_path, settings_path)
print("settings.json patched.")
PYEOF

echo ""
echo "==> Installation complete."
echo "    Commands available: /nen-contract, /pev-loop-human-handoff-v2"
echo "    Hook installed:     ~/.claude/hooks/validate_contract.py"
echo "    Restart Claude Code to activate the commands."
