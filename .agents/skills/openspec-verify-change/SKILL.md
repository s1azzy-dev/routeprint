---
name: openspec-verify-change
description: Verify implementation matches change artifacts. Use when the user wants to validate that implementation is complete, correct, and coherent before archiving.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

Verify that an implementation matches the change artifacts (specs, tasks, design).

**Routeprint CLI rule:** run OpenSpec through the repository wrapper:
`bin/openspec ...`. Do not use a bare `openspec` command in this checkout.

**Proof model:** this skill produces an agentic verification report. Keyword
search, file-path analysis, and implementation inference are advisory evidence,
not blocking proof. Only mechanical validation, narrow tests, and project gates
from `docs/DEVELOPMENT.md` can prove readiness to archive or merge.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `bin/openspec list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show changes that have implementation tasks (tasks artifact exists).
   Include the schema used for each change if available.
   Mark changes with incomplete tasks as "(In Progress)".

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check status to understand the schema**
   ```bash
   bin/openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context
   - Which artifacts exist for this change

   If status reports `actionContext.mode: "workspace-planning"`, explain that full workspace implementation verification is not supported in this slice and STOP. Do not infer repo-local implementation ownership or edit linked repos.

3. **Get planning context and load artifacts**

   ```bash
   bin/openspec instructions apply --change "<name>" --json
   ```

   This returns the change directory and `contextFiles` (artifact ID -> array of concrete file paths). Read all available artifacts from `contextFiles`.

4. **Initialize verification report structure**

   Create a report structure with three dimensions:
   - **Completeness**: Track tasks and spec coverage
   - **Correctness**: Track requirement implementation and scenario coverage
   - **Coherence**: Track design adherence and pattern consistency

   Each dimension can have CRITICAL, WARNING, or SUGGESTION issues.

5. **Verify Completeness**

   **Task Completion**:
   - If `contextFiles.tasks` exists, read every file path in it
   - Parse checkboxes: `- [ ]` (incomplete) vs `- [x]` (complete)
   - Count complete vs total tasks
   - If incomplete tasks exist:
     - Add CRITICAL issue for each incomplete task
     - Recommendation: "Complete task: <description>" or "Mark as done if already implemented"

   **Spec Coverage**:
   - If delta specs exist in `contextFiles.specs`:
     - Extract all requirements (marked with "### Requirement:")
     - For each requirement:
       - Search codebase for keywords related to the requirement
       - Assess whether implementation evidence likely exists
     - If requirements appear unimplemented:
       - Add WARNING unless mechanical evidence proves the requirement is
         missing. Use CRITICAL only for objective task/spec/gate blockers.
         "Requirement evidence not found: <requirement name>"
       - Recommendation: "Implement requirement X: <description>"

6. **Verify Correctness**

   **Requirement Implementation Mapping**:
   - For each requirement from delta specs:
     - Search codebase for implementation evidence
     - If found, note file paths and line ranges
     - Assess if implementation matches requirement intent
     - If divergence detected:
       - Add WARNING: "Implementation may diverge from spec: <details>"
       - Recommendation: "Review <file>:<lines> against requirement X"

   **Scenario Coverage**:
   - For each scenario in delta specs (marked with "#### Scenario:"):
     - Check if conditions are handled in code
     - Check if tests exist covering the scenario
     - If scenario appears uncovered:
       - Add WARNING: "Scenario not covered: <scenario name>"
       - Recommendation: "Add test or implementation for scenario: <description>"

7. **Verify Coherence**

   **Design Adherence**:
   - If `contextFiles.design` exists:
     - Extract key decisions (look for sections like "Decision:", "Approach:", "Architecture:")
     - Verify implementation follows those decisions
     - If contradiction detected:
       - Add WARNING: "Design decision not followed: <decision>"
       - Recommendation: "Update implementation or revise design.md to match reality"
   - If no design.md: Skip design adherence check, note "No design.md to verify against"

   **Code Pattern Consistency**:
   - Review new code for consistency with project patterns
   - Check file naming, directory structure, coding style
   - If significant deviations found:
     - Add SUGGESTION: "Code pattern deviation: <details>"
     - Recommendation: "Consider following project pattern: <example>"

8. **Generate Verification Report**

   **Summary Scorecard**:
   ```
   ## Verification Report: <change-name>

   ### Summary
   | Dimension            | Status                 |
   |----------------------|------------------------|
   | Mechanical proof     | tests/gates run or missing |
   | Completeness         | X/Y tasks, N reqs      |
   | Agentic mapping      | M/N reqs have evidence |
   | Coherence            | Followed/Issues        |
   ```

   **Issues by Priority**:

   1. **CRITICAL** (Must fix before archive):
      - Incomplete tasks
      - Missing required mechanical validation
      - Mechanically proven missing requirement implementations
      - Each with specific, actionable recommendation

   2. **WARNING** (Should fix):
      - Spec/design divergences
      - Missing scenario coverage
      - Requirements with weak or missing search evidence
      - Each with specific recommendation

   3. **SUGGESTION** (Nice to fix):
      - Pattern inconsistencies
      - Minor improvements
      - Each with specific recommendation

   **Final Assessment**:
   - If CRITICAL issues: "X critical issue(s) found. Fix before archiving."
   - If only warnings and mechanical proof is present: "No critical issues. Y warning(s) to consider. Mechanically ready if the recorded gates passed."
   - If all clear and mechanical proof is present: "Agentic checks found no issues; recorded mechanical gates are the readiness proof."
   - If mechanical proof is missing: "Agentic checks completed, but readiness is unproven until required gates run."

**Verification Heuristics**

- **Completeness**: Focus on objective checklist items (checkboxes, requirements list)
- **Correctness**: Use keyword search, file path analysis, reasonable inference - don't require perfect certainty and do not present inference as proof
- **Coherence**: Look for glaring inconsistencies, don't nitpick style
- **False Positives**: When uncertain, prefer SUGGESTION over WARNING, WARNING over CRITICAL. Reserve CRITICAL for objective artifact, task, spec, or gate blockers.
- **Actionability**: Every issue must have a specific recommendation with file/line references where applicable

**Mechanical Proof Required**

Before saying a change is ready to archive, record:
- `bin/openspec validate <change> --strict` when validating one change, or
  `bin/openspec validate --all --strict` when checking all artifacts
- the narrow specs/tests required by the change
- the applicable `docs/DEVELOPMENT.md` verification gate
- any unrelated existing blocker exactly

**Graceful Degradation**

- If only tasks.md exists: verify task completion only, skip spec/design checks
- If tasks + specs exist: verify completeness and correctness, skip design
- If full artifacts: verify all three dimensions
- Always note which checks were skipped and why

**Output Format**

Use clear markdown with:
- Table for summary scorecard
- Grouped lists for issues (CRITICAL/WARNING/SUGGESTION)
- Code references in format: `file.ts:123`
- Specific, actionable recommendations
- No vague suggestions like "consider reviewing"
