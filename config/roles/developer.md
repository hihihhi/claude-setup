# Role: Developer

## Phase Routing

| Trigger | Action |
|---------|--------|
| "new project" | `/dev-workflow` Phase 0 (scaffold) |
| "new feature" | `/dev-workflow` Phase 2 (implement) |
| bug / error / stack trace | `/investigate` |
| "refactor" | `/review` then implement |
| "test" / "QA" | `/qa` or `/tdd` |
| "review code" / PR ready | `/review` then `/code-review` |
| "ship" / "deploy" | `/ship` |
| build failure | `/build-error-resolver` |

## Priority Skills

| Category | Skills |
|----------|--------|
| Core workflow | `tdd`, `code-review`, `commit`, `create-pr` |
| Security | `security-review`, `insecure-defaults` |
| Build | `build-error-resolver` |
| Testing | `webapp-testing`, `tdd`, `property-based-testing` |
| Quality | `simplify`, `code-simplifier`, `refactor-module` |
| Architecture | `dev-workflow`, `plan` |

## Preferred Agents

| Agent | Role | Model |
|-------|------|-------|
| Architect | Design decisions, API contracts, data models | Opus |
| Implementer | Write code, follow specs | Sonnet |
| Reviewer | Code review, security audit, quality check | Sonnet |
| Tester | Write and run tests, coverage analysis | Sonnet |

## Workflow

1. **Understand**: Read issue/spec. Clarify if success criteria unknown.
2. **Plan**: 3-5 steps + risk/recovery. Architect agent for non-trivial design.
3. **Test first**: Write failing test (TDD). Use `webapp-testing` or `tdd` skill.
4. **Implement**: Sonnet agent. Max 400 lines. One concern per file.
5. **Review**: Separate reviewer agent. Run `security-review` on auth/data paths.
6. **Verify**: All tests pass, no regressions, build succeeds.
7. **Commit**: Conventional commit. Update `state.md`.

## Code Standards
- Functions do one thing. Max 100 char lines.
- No dead code. No commented-out code.
- Validate at boundaries only.
- Error handling: explicit, no silent swallows.
- Types: strict mode. No `any` in TypeScript.
