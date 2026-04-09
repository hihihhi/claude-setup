# Attribution

This Claude Code setup bundles and builds upon the following open-source components.

## Bundled Components

| Component | License | Copyright | Repository |
|-----------|---------|-----------|------------|
| everything-claude-code | MIT | Affaan Mustafa | [github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) |
| superpowers | MIT | Jesse Vincent | [github.com/obra/superpowers](https://github.com/obra/superpowers) |
| mattpocock/skills | MIT | Matt Pocock | [github.com/mattpocock/skills](https://github.com/mattpocock/skills) |
| agency-agents | MIT | Maciej Sitarzewski | [github.com/msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) |
| impeccable | Apache 2.0 | Paul Bakaus | [github.com/pbakaus/impeccable](https://github.com/pbakaus/impeccable) |
| claude-hud | MIT | Jarrod Watts | [github.com/jarrodwatts/claude-hud](https://github.com/jarrodwatts/claude-hud) |
| last30days-skill | MIT | mvanhorn | [github.com/mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) |
| claude-scientific-skills | MIT | K-Dense AI | [github.com/K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) |
| deer-flow | MIT | ByteDance | [github.com/bytedance/deer-flow](https://github.com/bytedance/deer-flow) |

## Skills Implemented From Patterns (not copied)

These components could not be bundled directly due to licensing, so we studied
their architecture and implemented equivalent functionality from scratch. No code
was copied — only the conceptual patterns were used as inspiration.

### `karpathy-guidelines` skill
**Inspired by:** [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) (MIT)
**What the original does:** A CLAUDE.md + skill file codifying four LLM coding principles
observed by Andrej Karpathy: Think Before Coding, Simplicity First, Surgical Changes,
Goal-Driven Execution.

**What we built:** `~/.claude/skills/karpathy-guidelines/SKILL.md` — an independently
written skill implementing the same four behavioral principles. The principles themselves
(verify before implementing, don't over-engineer, minimize diff scope, define success
criteria) are general software engineering best practices, not copyrightable expression.
Our implementation uses original wording, different examples, and a different structure.

**Key patterns implemented:**
- Goal-driven execution: imperative → declarative goal transformation table
- Concise verification checkpoints per step
- Self-test questions to catch overcomplication
- Diff-minimality rule ("every changed line traces to the request")

---

### `deep-research` skill
**Inspired by:** [Imbad0202/academic-research-skills](https://github.com/Imbad0202/academic-research-skills) (CC BY-NC 4.0)
**What the original does:** A 13-agent, 10-stage academic research pipeline with anti-sycophancy
mechanisms (concession scoring, intent detection, dialogue health monitoring), IRON RULE
context anchors, cross-model verification, and material passport provenance tracking.

**What we built:** `~/.claude/skills/deep-research/SKILL.md` — an independently written
5-stage research pipeline implementing equivalent patterns. No code or prose was copied
from the original. The conceptual patterns (anti-sycophancy guards, source provenance
tracking, verification gates, context anchors) are research methodology concepts, not
copyrightable expression.

**Key patterns implemented:**
- IRON RULE markers: context anchors that prevent goal drift in long sessions
- Anti-sycophancy rules: intent detection, concession floor (20% contrary evidence required),
  dialogue health checks (3-agreement-in-a-row = search harder for dissent)
- Material passport: source ledger with claim traceability from synthesis back to original source
- 4 depth modes: flash / standard / pro / deep (maps to original's flash/standard/pro/ultra)
- Verification gate: 3 independent sources required before synthesis

---

## Not Bundled (License Restrictions)

| Component | License | Reason | Repository |
|-----------|---------|--------|------------|
| academic-research-skills | CC BY-NC 4.0 | Non-commercial; patterns reimplemented above | [github.com/Imbad0202/academic-research-skills](https://github.com/Imbad0202/academic-research-skills) |
| andrej-karpathy-skills | MIT | Patterns reimplemented above | [github.com/forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) |

## Educational References (not installed)

These repositories were studied for architectural patterns but not installed:

| Component | License | What we learned | Repository |
|-----------|---------|-----------------|------------|
| learn-claude-code | MIT | Harness = Agent - Model formula; three-tier memory pattern | [github.com/shareAI-lab/learn-claude-code](https://github.com/shareAI-lab/learn-claude-code) |
| hermes-agent | MIT | Three-level memory architecture validation | [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |

## License Compliance Notes

- **MIT-licensed components**: Included per MIT terms. Original copyright notices are
  preserved in the `licenses/` directory.
- **Apache 2.0 components** (impeccable): Included per Apache 2.0 terms. NOTICE file
  requirements are satisfied in `licenses/`.
- **Pattern-derived skills**: Independently written implementations. No original source
  code or prose copied. General concepts and methodology patterns are not copyrightable.
- All modifications to bundled components are documented in commit history.
- This project itself is licensed under [MIT](./LICENSE).
