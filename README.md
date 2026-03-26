# nen-contract Plugin

## What this plugin does

The nen-contract plugin installs a Planner Executor Verifier (PEV) orchestration system into Claude Code. It provides two global slash commands, /nen-contract and /pev-loop-human-handoff-v2, along with a PostToolUse hook that automatically validates PEV contract files as they are written.

The system enforces a structured loop in which a Planner designs the solution, a human reviews the plan, an Executor implements it, and a Verifier independently tests the output. Each agent runs in a fully isolated context window. Contracts are passed between agents through files on disk, which helps prevent context bleed between roles.

This orchestration system is influenced by ecological dynamics. It treats constraints as active shapers of behaviour rather than as mere limitations. In practice, the system uses constraints to structure the affordance landscape of each agent, guiding what actions are available, relevant, and appropriate at each phase of the loop. These constraints also help stabilize task attractors, so the workflow is pulled toward disciplined planning, bounded execution, and independent verification rather than drifting into role confusion or unstructured iteration.

A mandatory human review gate sits between the Planner and Executor phases. The Executor to Verifier handoff is automatic. The system allows no more than two attempts before requiring human intervention.

I can also turn this into a more formal technical description or a sharper README-style paragraph.

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [Python 3](https://www.python.org/downloads/) on your PATH
- [Git](https://git-scm.com/downloads) installed

## Install — Windows

Open PowerShell and run:

```powershell
git clone https://github.com/doner21/nen-contract.git
cd nen-contract
.\install.bat
```

Then **restart Claude Code**. The `/nen-contract` command will be available in any project.

> If you already have a clone from a previous install, run `git pull` first to get the latest version before running `.\install.bat`.

## Install — Mac/Linux

Open a terminal and run:

```bash
git clone https://github.com/doner21/nen-contract.git
cd nen-contract
chmod +x install.sh
./install.sh
```

Then **restart Claude Code**.

## What the install script does

- Copies `nen-contract.md` and `pev-loop-human-handoff-v2.md` to `~/.claude/commands/`
- Copies `validate_contract.py` to `~/.claude/hooks/`
- Patches `~/.claude/settings.json` to register the PostToolUse hook on Write and Edit events

All changes are scoped to your user profile — no project files are modified.

## How to use /nen-contract

After installation, invoke the orchestrator from any Claude Code project with a task description:

```
/nen-contract Refactor the authentication module to use JWT tokens
```

The orchestrator will:
1. Spawn a Planner subagent to produce a plan and `contracts/EXE_BRIEF.md`
2. Pause and ask you to review the plan before continuing
3. After you reply **go**, spawn an Executor subagent to implement the plan
4. Automatically spawn a Verifier subagent to test the implementation
5. Report PASS or FAIL, with up to one retry cycle

All plan documents, contracts, and verification reports are written to `markdown/` and `contracts/` directories in your project.

## Uninstall — Unix/Mac

```sh
chmod +x uninstall.sh && ./uninstall.sh
```

Removes the two command files, the hook script, and the nen-contract hook entries from `~/.claude/settings.json`. All other settings entries are preserved.

## Uninstall — Windows

```bat
uninstall.bat
```

Windows equivalent of the Unix uninstall.

## What the hook does

The `validate_contract.py` hook fires automatically after every `Write` or `Edit` tool call in Claude Code. When the written file is a PEV contract (detected by filename pattern — e.g., files in `contracts/` or `markdown/` with `ATTEMPT_` in the name), the hook:

1. Detects the PEV role from the filename (`PLANNER_TO_EXECUTION` → Planner, `EXECUTION_TO_VERIFIER` → Executor, `VERIFIER` → Verifier)
2. Checks that required ID tags are present:
   - Planner contracts must contain `[INV_001]`, `[INV_002]`, ... tags on each invariant/constraint
   - Executor contracts must contain `[EXEC_001]`, `[EXEC_002]`, ... tags on each output item
   - Verifier contracts must contain `[SUC_001]`, `[SUC_002]`, ... tags on each success criterion
3. If tags are missing, writes `contracts/NUDGE.md` explaining what needs to be fixed and exits with code 2, causing Claude Code to surface the validation failure
4. If tags are present, writes `contracts/<ROLE>_VALIDATED.md` and exits cleanly

This ensures all PEV loop artifacts are consistently structured and traceable before the next agent receives them.

---

To push this plugin to your own GitHub repository:

```sh
git remote add origin https://github.com/YOUR_USERNAME/nen-contract-plugin.git
git push -u origin main
```
