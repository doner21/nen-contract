@echo off
REM uninstall.bat — Remove the nen-contract PEV plugin from Claude Code (Windows)
REM Run from the nen-contract-plugin\ directory: uninstall.bat

setlocal enabledelayedexpansion

echo =^> Uninstalling nen-contract PEV plugin...

REM 1. Remove command files
if exist "%USERPROFILE%\.claude\commands\nen-contract.md" (
    del /F /Q "%USERPROFILE%\.claude\commands\nen-contract.md"
    echo [1/4] Removed %USERPROFILE%\.claude\commands\nen-contract.md
) else (
    echo [1/4] %USERPROFILE%\.claude\commands\nen-contract.md not found, skipping
)

if exist "%USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md" (
    del /F /Q "%USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md"
    echo [2/4] Removed %USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md
) else (
    echo [2/4] %USERPROFILE%\.claude\commands\pev-loop-human-handoff-v2.md not found, skipping
)

REM 3. Remove hook script
if exist "%USERPROFILE%\.claude\hooks\validate_contract.py" (
    del /F /Q "%USERPROFILE%\.claude\hooks\validate_contract.py"
    echo [3/4] Removed %USERPROFILE%\.claude\hooks\validate_contract.py
) else (
    echo [3/4] %USERPROFILE%\.claude\hooks\validate_contract.py not found, skipping
)

REM 4. Patch settings.json to remove nen-contract hook entries
echo [4/4] Patching %USERPROFILE%\.claude\settings.json to remove nen-contract hook entries...
python "%PLUGIN_DIR%patch_settings.py" uninstall

echo.
echo =^> Uninstall complete.
echo     Restart Claude Code to deactivate the removed commands.

endlocal
