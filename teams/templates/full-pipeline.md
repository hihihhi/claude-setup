# Full Pipeline Team Template

Research-to-ship pipeline team. Orchestrates discovery, implementation, and quality
in a single coordinated workflow.

## Team Structure

```
Director (Opus) -- orchestrates research -> dev -> ship
  |-- Research Pod
  |     |-- Researcher (Sonnet) -- web search, source gathering, evidence collection
  |     +-- Analyst (Sonnet) -- data synthesis, comparison, structured summaries
  |-- Dev Pod
  |     |-- Implementer (Sonnet) -- feature implementation, max 400 lines/session
  |     +-- Tester (Sonnet) -- TDD, coverage verification, 5-component evaluation
  +-- Quality Pod
        |-- Reviewer (Sonnet) -- code review, Generator!=Evaluator, anti-sycophancy
        +-- Security (Sonnet) -- security scan, dependency audit, threat modeling
```

## Agent Definitions

### Director
- **Model**: Opus
- **Role**: Orchestrates the entire pipeline from research through shipping. Manages
  phase transitions, resolves cross-pod conflicts, and makes go/no-go decisions.
- **Skills**: `plan`, `architecture-decision-records`
- **Constraints**: Coordination only. Does not perform research or write code.

### Research Pod

#### Researcher
- **Model**: Sonnet
- **Role**: Primary information gathering. Searches web, reads docs, collects evidence
  for the problem domain before any code is written.
- **Skills**: `deep-research`, `last30days`, `exa-search`
- **Output**: Raw findings with source URLs and confidence ratings.

#### Analyst
- **Model**: Sonnet
- **Role**: Processes Researcher output into actionable technical recommendations.
  Compares approaches, evaluates trade-offs, produces decision matrices.
- **Skills**: `scenario-analyzer`, `data-quality-checker`
- **Output**: Technical recommendation document with options ranked by criteria.

### Dev Pod

#### Implementer
- **Model**: Sonnet
- **Role**: Builds the feature based on Director's plan and Analyst's recommendations.
  Works in isolated worktree. Follows conventional commits.
- **Skills**: Context-dependent (loaded based on project stack)
- **Constraints**: Max 400 lines per session. Non-overlapping file domains.

#### Tester
- **Model**: Sonnet
- **Role**: Writes tests before implementation (TDD). After implementation, runs
  5-component evaluation: output validation, environment check, automated tests,
  log inspection, error attribution.
- **Skills**: `tdd`, `webapp-testing`, `coverage-analysis`
- **Output**: Test suite, coverage report, evaluation results.

### Quality Pod

#### Reviewer
- **Model**: Sonnet
- **Role**: Reviews all code produced by Implementer. Generator != Evaluator -- Reviewer
  never sees the implementation context, only the diff. Checks for correctness,
  maintainability, and adherence to the plan.
- **Skills**: `code-review`, `critique`, `second-opinion`
- **Output**: Review report with approve/request-changes verdict.

#### Security
- **Model**: Sonnet
- **Role**: Dedicated security agent. Scans for hardcoded secrets, injection
  vulnerabilities, insecure defaults, dependency CVEs, and OWASP Top 10 issues.
- **Skills**: `security-review`, `insecure-defaults`, `supply-chain-risk-auditor`
- **Output**: Security report with severity ratings (Critical/High/Medium/Low).

## Phase Transitions

The pipeline has five phases. Director controls transitions via go/no-go gates.

```
Phase 1: RESEARCH
  Researcher + Analyst work in parallel
  Gate: Director reviews recommendations, approves approach
          |
          v
Phase 2: PLAN
  Director creates architecture plan + file assignments
  Tester writes failing tests based on spec
  Gate: Tests exist and fail (TDD red phase)
          |
          v
Phase 3: IMPLEMENT
  Implementer builds feature to make tests pass
  Gate: All tests pass, coverage meets threshold
          |
          v
Phase 4: REVIEW
  Reviewer + Security work in parallel
  Gate: No blocking findings from either agent
          |
          v
Phase 5: SHIP
  Director merges, tags release, updates state
  Gate: CI green, all reviews approved
```

## Handoff Protocols

### Research -> Plan Handoff
The Analyst produces a **Technical Recommendation Document**:
```markdown
## Problem Statement
[From Director's original prompt]

## Research Summary
[Key findings from Researcher, synthesized by Analyst]

## Recommended Approach
[Ranked options with trade-off analysis]

## Dependencies & Risks
[External deps, known risks, mitigation strategies]

## Sources
[All URLs cited]
```
Director uses this to create the architecture plan.

### Plan -> Implement Handoff
Director produces an **Implementation Plan**:
```markdown
## Architecture Decision
[Chosen approach from recommendations, with rationale]

## File Assignments
[Which files the Implementer owns]

## Interface Contracts
[API signatures, data shapes, integration points]

## Test References
[Links to tests written by Tester that must pass]

## Constraints
- Max 400 lines
- Conventional commits
- No modifications outside assigned files
```

### Implement -> Review Handoff
Tester produces an **Evaluation Report**:
```markdown
## Test Results
[Pass/fail summary]

## Coverage
[Line/branch/function coverage percentages]

## 5-Component Evaluation
1. Output validation: [pass/fail]
2. Environment check: [pass/fail]
3. Automated tests: [pass/fail]
4. Log inspection: [pass/fail]
5. Error attribution: [pass/fail]
```
Reviewer and Security receive the diff + evaluation report (not the implementation
conversation).

### Review -> Ship Handoff
Quality Pod produces a **Release Clearance**:
```markdown
## Code Review
- Verdict: [Approved / Changes Requested]
- Findings: [itemized list]

## Security Review
- Verdict: [Approved / Changes Requested]
- Critical: [count]
- High: [count]
- Medium: [count]
- Low: [count]
- Findings: [itemized list]
```
Director merges only if both verdicts are "Approved."

## Coordination Rules

1. **Pods are context-isolated**: Agents within a pod share context. Agents across
   pods communicate only through structured handoff documents.

2. **Generator != Evaluator**: No agent reviews its own output. The Quality Pod is
   always staffed by agents that did not participate in Research or Dev.

3. **Phase gates are mandatory**: Director cannot skip a phase. If a gate fails,
   the pipeline loops back to the previous phase.

4. **Escalation path**: If Security finds a Critical issue, the pipeline halts
   until Director explicitly addresses it. No auto-proceed on Critical findings.

5. **Context reset**: Any agent showing quality degradation gets replaced with
   a fresh instance plus a handover state document.

6. **State tracking**: Director updates `.claude/state.md` at each phase transition
   with current phase, completed gates, and pending blockers.

## Usage

```bash
# From project root, invoke the full pipeline:
claude --team teams/templates/full-pipeline.md \
  --prompt "Research and build [feature]: [description]"
```

## When to Use

- Greenfield features requiring upfront research
- High-stakes changes where security review is mandatory
- Features where the approach is uncertain and needs investigation first
- Full product lifecycle from idea to shipped code
