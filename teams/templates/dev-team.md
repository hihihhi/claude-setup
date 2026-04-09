# Dev Team Template

Multi-agent development team for feature implementation with quality gates.

## Team Structure

```
Architect (Opus) -- design, plan, coordinate implementation
  |-- Implementer-1 (Sonnet) -- feature implementation in worktree A
  |-- Implementer-2 (Sonnet) -- feature implementation in worktree B
  |-- Tester (Sonnet) -- TDD, write tests first, verify coverage
  +-- Reviewer (Sonnet) -- code review, security scan, Generator!=Evaluator
```

## Agent Definitions

### Architect
- **Model**: Opus
- **Role**: Designs the solution, breaks work into non-overlapping file domains,
  assigns tasks to Implementers, resolves integration conflicts.
- **Skills**: `plan`, `architecture-decision-records`, `api-design`
- **Constraints**: Does not write production code. Designs, coordinates, and
  resolves conflicts only.
- **Output**: Architecture plan with file-domain assignments, interface contracts,
  and integration sequence.

### Implementer-1
- **Model**: Sonnet
- **Role**: Implements assigned feature scope in worktree A. Owns a non-overlapping
  set of files defined by Architect.
- **Skills**: Context-dependent (e.g., `next-best-practices`, `modern-python`,
  `rust-patterns`)
- **Isolation**: Git worktree A. Cannot modify files assigned to Implementer-2.
- **Constraints**: Max 400 lines changed per session. Conventional commits.

### Implementer-2
- **Model**: Sonnet
- **Role**: Implements assigned feature scope in worktree B. Owns a non-overlapping
  set of files defined by Architect.
- **Skills**: Context-dependent
- **Isolation**: Git worktree B. Cannot modify files assigned to Implementer-1.
- **Constraints**: Max 400 lines changed per session. Conventional commits.

### Tester
- **Model**: Sonnet
- **Role**: Writes tests BEFORE implementation begins (TDD). Verifies coverage after
  implementation. Runs the 5-component evaluation: output validation, env check,
  automated tests, logging, error attribution.
- **Skills**: `tdd`, `webapp-testing`, `coverage-analysis`
- **Output**: Test files, coverage report, pass/fail summary.

### Reviewer
- **Model**: Sonnet
- **Role**: Reviews all code from Implementers. Performs security scan, checks for
  dead code, validates against Architect's design. Generator != Evaluator -- Reviewer
  never writes the code it reviews.
- **Skills**: `code-review`, `security-review`, `insecure-defaults`
- **Output**: Review report with approve/request-changes, itemized findings.

## Coordination Rules

1. **Non-overlapping file domains**: Architect assigns each file to exactly one
   Implementer. No file is modified by two agents. This eliminates merge conflicts.

2. **Worktree isolation**: Each Implementer works in a separate git worktree.
   ```bash
   git worktree add ../worktree-a feature/part-a
   git worktree add ../worktree-b feature/part-b
   ```

3. **Max 400 lines per agent session**: If an Implementer needs more, Architect
   splits the task into additional sessions or agents.

4. **TDD flow**:
   - Phase 1: Tester writes failing tests based on Architect's spec.
   - Phase 2: Implementers make tests pass.
   - Phase 3: Tester verifies coverage and runs full suite.

5. **Generator != Evaluator**: The Reviewer must be a separate agent from the
   Implementers. Reviewer receives the diff cold, without implementation context.

6. **Commit conventions**: All commits use conventional format:
   - `feat:` new feature
   - `fix:` bug fix
   - `test:` test additions/changes
   - `refactor:` code restructuring
   - `chore:` tooling, config
   - `docs:` documentation

7. **Integration sequence**:
   - Implementer-1 merges to feature branch first.
   - Implementer-2 rebases on updated feature branch, resolves any interface
     mismatches, then merges.
   - Architect verifies integration.
   - Full test suite runs.
   - Reviewer performs final review on the integrated result.

8. **Context reset**: If any agent's output quality degrades, spawn a fresh agent
   with a handover state document. Do not rely on context compaction.

## Phase Flow

```
Architect: Design + Plan
        |
        v
Tester: Write failing tests (TDD)
        |
        v
Implementer-1 + Implementer-2: Parallel implementation
        |
        v
Tester: Verify tests pass + coverage
        |
        v
Architect: Integration verification
        |
        v
Reviewer: Code review + security scan
        |
        v
Architect: Final approval -> merge to main
```

## Usage

```bash
# From project root, invoke the dev team:
claude --team teams/templates/dev-team.md \
  --prompt "Implement [feature]: [spec or ticket link]"
```

## When to Use

- Features spanning 2+ files that benefit from parallel implementation
- Any change where security review is required
- Work that needs TDD discipline enforced by process
- Large features that exceed single-agent context limits
