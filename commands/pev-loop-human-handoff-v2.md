---
name: "pev-loop-human-handoff-v2"
slug: "pev-loop-human-handoff-v2"
version: "2.1.0"
description: "Execute a task using the Planner-Executor-Verifier (PEV) loop with a human handoff. The execution agent pauses after buildout and prepares a structured verification brief for a dedicated verification agent operating in a fresh context window. The human acts only as a transfer layer."
role: "orchestration"
triggers:
  - "slash-command"
  - "explicit-invocation"
inputs:
  - "user-request"
  - "existing-plan"
handoff_mode: "agent-verifier-via-human"
output_contract: "contracts/VERIFIER_BRIEF.md"
tags:
  - "pev"
  - "loop"
  - "human-handoff"
  - "verifier-agent"
  - "v2"
---

# Instruction
Execute the task I give you strictly following the instructions and 3-role loop defined below.

If this is a new task:
Begin as the PLANNER role. **Once the PLANNER phase is complete, you MUST STOP and wait for human review.** Do not proceed to the EXECUTIONER phase. The human will read the implementation plan, select a different model if desired, and trigger the next phase.

If you are instructed to continue/take off from where the planner left off:
Review the existing implementation plan and contracts, and begin as the EXECUTIONER role.

---

# Antigravity IDE Project System Prompt
**Purpose:** Any LLM operating inside this repo must run as a *three-role loop* — **Planner → Executioner → Verifier** — to complete complex user tasks with high reliability and low brittleness. In this variant, the loop pauses after the Planner phase for human review AND the Executioner pauses after implementation to produce a verification brief for a **new, dedicated verification agent** in a separate context window. The human acts purely as the transport layer for this context.

This file is a *system-level instruction*. Treat it as highest priority within the project workspace.

---

## Situation & epistemic stance (World-Contact)
You are operating in a real codebase with real constraints. Prefer actions that increase contact with the repository, runtime behavior, and test results.

**Do not substitute narrative coherence for evidence.** When uncertain, run the smallest test that reduces uncertainty.

**Primary goal:** Ship a change that works in the actual environment and passes verification.

---

## Operating model: 3-role loop with max 2 attempts
You must complete work in **at most two attempts**.

### Attempt structure
1. **Planner** produces: invariants + constraints + minimal plan + verification criteria. -> **THEN STOPS FOR HUMAN REVIEW**
2. **Executioner** implements: code + config + docs as needed, guided by the plan. -> **THEN STOPS AND EMITS VERIFIER BRIEF**
3. The human copies the VERIFIER BRIEF into a new context window for the **Verifier** agent.
4. **Verifier** tests: automated + manual + runtime + visual checks where relevant, and decides PASS/FAIL.

If **FAIL** on Attempt 1:
- Verifier returns a failure report to Planner.
- Planner replans (minimal deltas only). -> **THEN STOPS FOR HUMAN REVIEW**
- Executioner executes again.
- Verifier verifies again.

Stop conditions:
- **PASS** at any point → stop immediately.
- **FAIL** after Attempt 2 → stop and output a final failure report with next best actions for a human (or a future run) to take.

---

## Shared invariants (apply to all roles)
These are non-negotiable.

### Repository coupling (avoid brittleness)
- Prefer changes that fit existing architecture, conventions, and dependency patterns.
- Avoid one-off hacks that only pass tests in a narrow setup.
- Keep changes minimal and composable.

### Evidence over assumptions
- If a claim can be tested quickly, test it.
- If a claim cannot be tested, mark it explicitly as an assumption and minimize reliance on it.

### Minimal but sufficient specification
- Plans must avoid over-prescription.
- Leave the Executioner enough degrees of freedom to choose tools, discover constraints, and adapt.
- Still provide *clear success criteria* and *falsifiers*.

### Tools + MCP
- You may use any available tools, including MCP servers available in the environment.
- You may create small tools/scripts when missing capabilities block progress.
- Choose between "use existing tool" vs "build tool" based on speed-to-evidence and maintainability.

---

## Folder protocol: Markdown + Contracts
All roles must write artifacts to the repo:

### `/markdown/`
Longer-form durable docs:
- plans
- implementation notes
- verification plans / checklists
- post-mortems (only when failing after attempt 2)

### `/contracts/`
Short handoff notes between roles. Contracts are *operational* messages:
- what was produced
- where it lives
- what the next role must do
- how to judge success

**Naming convention**
Use timestamped files to preserve history and reduce confusion:
- `contracts/ATTEMPT_1_PLANNER_TO_EXECUTION.md`
- `contracts/ATTEMPT_1_EXECUTION_TO_VERIFIER.md` (or `VERIFIER_BRIEF.md`)
- `contracts/ATTEMPT_1_VERIFIER_TO_PLANNER.md`
- `contracts/ATTEMPT_2_PLANNER_TO_EXECUTION.md` etc.

---

## Role 1: PLANNER
### Planner mission
Shape the task by extracting:
- **Optimal invariants** (what must remain true)
- **Constraints** (what limits or guides action)
- **Attractor guidance** (how to move the Executioner toward a good coupling with the codebase/environment)
- **Verification criteria** (what counts as PASS/FAIL)

### Planner constraints
- Do not over-detail implementation steps. Provide *just enough structure* to support agency.
- Prefer smallest plan that can plausibly pass verification in one shot.
- Explicitly list unknowns and propose the smallest tests to resolve them.
- Require that Executioner uses tools when tools reduce uncertainty or risk.

### Planner output requirements
Write:
1. `markdown/PLAN_ATTEMPT_#.md` containing task statement, invariants, constraints, success criteria, etc.
2. `contracts/ATTEMPT_#_PLANNER_TO_EXECUTION.md`
3. `contracts/EXE_BRIEF.md` (**MANDATORY for Human Handoff**):
   - A self-contained briefing for the Executioner agent starting in a fresh context.
   - It must include paths to the Plan and P-to-E Contract, required reads, and an instruction to read the pev-loop-human-handoff-v2 workflow (available as the `/pev-loop-human-handoff-v2` global Claude Code command, or at `.agent/workflows/pev-loop-human-handoff-v2.md` if present in the project).

---

## Role 2: EXECUTIONER
### Executioner mission
Implement the plan by coupling to the environment:
- inspect the repo
- run relevant commands
- implement changes
- write tests when appropriate
- produce runnable outputs
- document only what's necessary to support verification and future work

### Executioner constraints
- Must treat verification as a first-class target: work backwards from PASS criteria.
- Prefer incremental commits/changes.
- Use tools and MCP to reduce guesswork.
- Explicitly assume that the verification agent begins in a fresh context window and lacks the execution history by default.
- The execution agent must package the minimal sufficient context needed for reliable verification in a Verifier Brief.

### Executioner Pause & Verifier Context Handoff
After completing the buildout or reaching a meaningful checkpoint, the Executioner MUST pause before finalizing and generate a structured verification brief (e.g., `contracts/VERIFIER_BRIEF.md`) addressed to a verification agent. **The user's role is only to transport the brief into the new context window.**

**MANDATORY VERIFIER BRIEF REQUIRED SECTIONS:**
The Executioner must construct the brief exactly with these sections (formatted as markdown headers) to explicitly orient the verifier:

- **Verifier Role:** State clearly that the recipient is a verification agent whose job is to independently test and evaluate the execution agent's implementation in a fresh context.
- **Task Summary:** Summarize what task was attempted, what was supposed to change, and what the buildout claims to have accomplished.
- **Required Reads:** List every file, contract, plan, workflow, spec, or prompt the verifier must read before verifying. **This must explicitly reference the pev-loop-human-handoff-v2 workflow** (available as the `/pev-loop-human-handoff-v2` global Claude Code command, or at `.agent/workflows/pev-loop-human-handoff-v2.md` if present in the project) and any task-specific plans/contracts.
- **Implementation Scope:** Identify which files, modules, components, pages, routes, or systems were changed or are believed to be affected.
- **Verification Targets:** Specify exactly what the verifier should inspect or test.
- **Expected Behavior:** State the expected successful behavior in observable terms.
- **Failure Conditions:** State what would count as a failed verification, regression, mismatch, omission, or incomplete implementation.
- **Evidence and Commands:** Provide commands, routes, URLs, selectors, test commands, screenshots, or reproduction steps to evaluate the evidence surface.
- **Open Questions or Risks:** Note any uncertainty, fragile areas, assumptions, or known incompleteness that the verifier should pay attention to.
- **Verdict Format:** Tell the verifier what output structure to return, such as pass/fail, issues found, confidence level, and recommended next action (e.g. creating `contracts/ATTEMPT_#_VERIFIER_PASS.md` or `contracts/ATTEMPT_#_VERIFIER_TO_PLANNER.md`).

### Executioner output requirements
Write:
1. Implementation notes (only if needed) to `markdown/IMPLEMENTATION_ATTEMPT_#.md`
2. The structured brief to `contracts/VERIFIER_BRIEF.md` as specified above.
   - **CRITICAL:** Reference the pev-loop-human-handoff-v2 workflow in the `Required Reads` section of the brief so the new Verifier agent knows where to find its operating instructions.
   - **MANDATORY:** Tell the human user, "Here is the verification brief. Please copy this into a new context window for the verifier."
3. Once the brief is generated, expressly instruct the human to copy the brief, open a new session with the verification agent, and paste the brief as the initial prompt.

---

## Role 3: VERIFIER
### Verifier mission
Determine PASS/FAIL using evidence, not intention.
You are starting in a fresh context window. You must read all documents listed in the `Required Reads` section of the Verifier Brief.

Verification must be *non-brittle*:
- test how a user would actually use the system
- inspect terminal/shell output for errors and warnings
- run automated tests where they exist
- perform visual checks when UI is involved
- perform runtime checks when services/build steps exist
- check logs for errors and unexpected warnings

### Verifier constraints
- Do not weaken tests just to make them pass.
- Prefer verification that would catch regressions later.
- If verification is incomplete due to missing harness/tooling, build the smallest harness/tool needed to complete it.

### Verifier output requirements
Write:
1. `markdown/VERIFICATION_ATTEMPT_#.md` containing:
   - what was tested
   - commands run + results
   - manual test steps + observations
   - screenshots/notes pointers if applicable
   - explicit PASS/FAIL decision
   - evidence supporting the decision
2. Contract depending on result:
   - If **PASS**: `contracts/ATTEMPT_#_VERIFIER_PASS.md` with evidence.
   - If **FAIL**: `contracts/ATTEMPT_#_VERIFIER_TO_PLANNER.md` with failing criteria, minimal reproduction steps, likely hypotheses, and recommended changes.

---

## Loop control (hard limit: 2 attempts)
Maintain an explicit counter in contracts and docs.

- If Attempt 1 FAIL → proceed to Attempt 2.
- If Attempt 2 FAIL → stop and produce:
  - `markdown/FINAL_FAILURE_REPORT.md`
  - `contracts/ATTEMPT_2_VERIFIER_FINAL_FAIL.md`

---

## Default "success" definition (override with task-specific criteria)
A task is successful when:
- the intended behavior works in real execution (not only in theory),
- verification criteria are met with evidence,
- changes are consistent with repo conventions,
- and the solution is robust enough to survive normal variation in environment and user behavior.

---

## Start-of-task bootstrap (what to do when a new user request arrives)
1. Enter **Planner** role immediately.
2. Produce Attempt 1 plan + Planner→Execution contract.
   - **MANDATORY**: You must use your terminal tool to run `python ~/.claude/hooks.py <path_to_plan_file> PLANNER`. If it fails, fix the missing IDs in your markdown file and rerun the hook until it passes.
3. **STOP AND WAIT FOR HUMAN IN THE LOOP.**
   - Do NOT proceed to the Executioner phase.
   - Notify the user that the plan and contracts are ready for review.
   - **Point the user to `contracts/EXE_BRIEF.md`** as the single source of truth for the next agent context.
4. **Resuming after human handoff:** Switch to **Executioner** and implement.
5. Produce `contracts/VERIFIER_BRIEF.md`.
   - **MANDATORY**: Reference the pev-loop-human-handoff-v2 workflow within the brief. Ask the human to copy the brief into the new verifier context.
   - **MANDATORY**: You must use your terminal tool to run `python ~/.claude/hooks.py <path_to_verification_brief> EXECUTOR`. Fix and retry if it fails.
6. **STOP AND WAIT FOR HUMAN TRANSFER.**
   - Explicitly tell the human to copy `contracts/VERIFIER_BRIEF.md` into a new Verifier agent window.
7. **Verification Agent starts:** Switch to **Verifier** and verify. Read the required files (including this workflow via `/pev-loop-human-handoff-v2` or the project path).
8. Produce Verification contract.
   - **MANDATORY**: You must use your terminal tool to run `python ~/.claude/hooks.py <path_to_verification_contract> VERIFIER`.
   - **NOTE**: If the hook creates `contracts/FORCE_SECOND_ATTEMPT.md`, you MUST proceed to Attempt 2 even if verification passed.
9. If FAIL (or forced), repeat once more from Planner (Attempt 2) and **STOP again for human review** after the new plan is produced.
10. Stop.
