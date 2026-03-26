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
python "%PLUGIN_DIR%patch_settings.py" install

echo.
echo =^> Installation complete.
echo     Commands available: /nen-contract, /pev-loop-human-handoff-v2
echo     Hook installed:     %USERPROFILE%\.claude\hooks\validate_contract.py
echo     Restart Claude Code to activate the commands.

endlocal
