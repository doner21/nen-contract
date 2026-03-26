@echo off
REM install.bat — Install the nen-contract PEV plugin globally for Claude Code (Windows)
REM Run from the nen-contract-plugin\ directory: install.bat

setlocal enabledelayedexpansion

set PLUGIN_DIR=%~dp0

echo =^> Installing nen-contract PEV plugin...

REM 1. Create %USERPROFILE%\.claude\commands\ if needed
mkdir "%USERPROFILE%\.claude\commands" 2>nul
echo [1/5] Created %USERPROFILE%\.claude\commands\ (if not present)

REM 2. Copy command files
copy /Y "%PLUGIN_DIR%commands\nen-contract.md" "%USERPROFILE%\.claude\commands\nen-contract.md" >nul
echo [2/5] Copied commands\nen-contract.md -^> %USERPROFILE%\.claude\commands\nen-contract.md

copy /Y "%PLUGIN_DIR%commands\pev-loop-human-handoff-v2.md" "%USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md" >nul
echo [2/5] Copied commands\pev-loop-human-handoff-v2.md -^> %USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md

REM 3. Create %USERPROFILE%\.claude\hooks\ if needed
mkdir "%USERPROFILE%\.claude\hooks" 2>nul
echo [3/5] Created %USERPROFILE%\.claude\hooks\ (if not present)

REM 4. Copy hook script
copy /Y "%PLUGIN_DIR%hooks\validate_contract.py" "%USERPROFILE%\.claude\hooks\validate_contract.py" >nul
echo [4/5] Copied hooks\validate_contract.py -^> %USERPROFILE%\.claude\hooks\validate_contract.py

REM 5. Patch %USERPROFILE%\.claude\settings.json
echo [5/5] Patching %USERPROFILE%\.claude\settings.json...
python -c "
import json, os, shutil, tempfile

settings_path = os.path.join(os.environ['USERPROFILE'], '.claude', 'settings.json')
data = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        data = json.load(f)

hooks = data.setdefault('hooks', {})
post = hooks.setdefault('PostToolUse', [])

NEN_CMD = 'python ' + os.path.join(os.environ['USERPROFILE'], '.claude', 'hooks', 'validate_contract.py')

for matcher in ('Write', 'Edit'):
    entry = next((e for e in post if e.get('matcher') == matcher), None)
    if entry is None:
        entry = {'matcher': matcher, 'hooks': []}
        post.append(entry)
    existing_cmds = [h.get('command') for h in entry.get('hooks', [])]
    if NEN_CMD not in existing_cmds:
        entry['hooks'].append({'type': 'command', 'command': NEN_CMD})

dir_ = os.path.dirname(settings_path) or '.'
with tempfile.NamedTemporaryFile('w', dir=dir_, delete=False, suffix='.tmp') as tmp:
    json.dump(data, tmp, indent=2)
    tmp_path = tmp.name
shutil.move(tmp_path, settings_path)
print('settings.json patched.')
"

echo.
echo =^> Installation complete.
echo     Commands available: /nen-contract, /pev-loop-human-handoff-v2
echo     Hook installed:     %USERPROFILE%\.claude\hooks\validate_contract.py
echo     Restart Claude Code to activate the commands.

endlocal
