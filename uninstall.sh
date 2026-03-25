#!/bin/sh
# uninstall.sh — Remove the nen-contract PEV plugin from the global Claude Code install
# Run from the nen-contract-plugin/ directory: chmod +x uninstall.sh && ./uninstall.sh

echo "==> Uninstalling nen-contract PEV plugin..."

# 1. Remove command files
if [ -f "$HOME/.claude/commands/nen-contract.md" ]; then
    rm "$HOME/.claude/commands/nen-contract.md"
    echo "[1/4] Removed ~/.claude/commands/nen-contract.md"
else
    echo "[1/4] ~/.claude/commands/nen-contract.md not found, skipping"
fi

if [ -f "$HOME/.claude/commands/pev-loop-human-handoff-v2.md" ]; then
    rm "$HOME/.claude/commands/pev-loop-human-handoff-v2.md"
    echo "[2/4] Removed ~/.claude/commands/pev-loop-human-handoff-v2.md"
else
    echo "[2/4] ~/.claude/commands/pev-loop-human-handoff-v2.md not found, skipping"
fi

# 3. Remove hook script
if [ -f "$HOME/.claude/hooks/validate_contract.py" ]; then
    rm "$HOME/.claude/hooks/validate_contract.py"
    echo "[3/4] Removed ~/.claude/hooks/validate_contract.py"
else
    echo "[3/4] ~/.claude/hooks/validate_contract.py not found, skipping"
fi

# 4. Patch ~/.claude/settings.json to remove nen-contract hook entries
echo "[4/4] Patching ~/.claude/settings.json to remove nen-contract hook entries..."
python3 - <<'PYEOF'
import json, os, shutil, tempfile

settings_path = os.path.expanduser("~/.claude/settings.json")
if not os.path.exists(settings_path):
    print("settings.json not found, nothing to patch.")
    exit(0)

with open(settings_path) as f:
    data = json.load(f)

NEN_CMD = "python ~/.claude/hooks/validate_contract.py"

post = data.get("hooks", {}).get("PostToolUse", [])
new_post = []
for entry in post:
    if entry.get("matcher") in ("Write", "Edit"):
        remaining = [h for h in entry.get("hooks", []) if h.get("command") != NEN_CMD]
        if remaining:
            entry["hooks"] = remaining
            new_post.append(entry)
        # else: matcher entry is now empty, drop it entirely
    else:
        new_post.append(entry)

data.setdefault("hooks", {})["PostToolUse"] = new_post

dir_ = os.path.dirname(settings_path) or "."
with tempfile.NamedTemporaryFile("w", dir=dir_, delete=False, suffix=".tmp") as tmp:
    json.dump(data, tmp, indent=2)
    tmp_path = tmp.name
shutil.move(tmp_path, settings_path)
print("settings.json entries removed.")
PYEOF

echo ""
echo "==> Uninstall complete."
echo "    Restart Claude Code to deactivate the removed commands."
