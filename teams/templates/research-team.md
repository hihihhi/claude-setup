# Research Team Template

Multi-agent research team for deep investigation, trend analysis, and synthesis.

## Team Structure

```
Team Lead (Opus) -- coordinates research, synthesizes findings
  |-- Researcher-1 (Sonnet) -- web search, trend analysis via last30days
  |-- Researcher-2 (Sonnet) -- deep dive on specific topics
  |-- Analyst (Sonnet) -- data analysis, comparison, fact synthesis
  +-- Reviewer (Sonnet) -- fact-check, anti-sycophancy gate, quality control
```

## Agent Definitions

### Team Lead
- **Model**: Opus
- **Role**: Breaks research question into sub-tasks, assigns to agents, synthesizes
  final output from all findings.
- **Skills**: `deep-research`, `market-environment-analysis`
- **Constraints**: Does not perform primary research. Coordinates only.

### Researcher-1
- **Model**: Sonnet
- **Role**: Broad search and trend discovery. Identifies sources, gathers data,
  surfaces emerging patterns.
- **Skills**: `last30days`, `market-news-analyst`, `exa-search`
- **Tools**: Tavily search, web fetch, MCP search
- **Output**: Structured findings with source URLs and confidence levels.

### Researcher-2
- **Model**: Sonnet
- **Role**: Deep dive on specific topics assigned by Team Lead. Follows leads from
  Researcher-1 or fills knowledge gaps identified during synthesis.
- **Skills**: `deep-research`, `sector-analyst`
- **Tools**: Tavily search, web fetch, context7 docs
- **Output**: Detailed topic reports with evidence chains.

### Analyst
- **Model**: Sonnet
- **Role**: Processes raw findings from both Researchers. Performs comparison,
  identifies contradictions, builds data tables, and creates structured summaries.
- **Skills**: `scenario-analyzer`, `data-quality-checker`
- **Output**: Comparative analysis, data tables, synthesized insights.

### Reviewer
- **Model**: Sonnet
- **Role**: Quality gate. Fact-checks all findings against sources. Flags unsupported
  claims, logical gaps, and confirmation bias. Applies anti-sycophancy filter.
- **Skills**: `second-opinion`, `critique`
- **Output**: Review report with pass/fail per section, flagged issues, confidence
  assessment.

## Coordination Rules

1. **Generator != Evaluator**: The Reviewer must never be the same agent that produced
   the findings. Reviewer receives outputs cold, without context of how they were made.

2. **Phased execution**:
   - Phase 1: Team Lead decomposes question into 2-4 sub-tasks.
   - Phase 2: Researcher-1 and Researcher-2 work in parallel on assigned sub-tasks.
   - Phase 3: Analyst receives all raw findings and produces structured synthesis.
   - Phase 4: Reviewer evaluates Analyst output for accuracy and completeness.
   - Phase 5: Team Lead produces final deliverable, incorporating Reviewer feedback.

3. **Source requirements**: Every factual claim must cite a source URL. No claim
   without evidence passes the Reviewer gate.

4. **Contradiction protocol**: When Researcher-1 and Researcher-2 findings conflict,
   Analyst must flag the contradiction explicitly. Team Lead decides resolution
   (additional research, weighted confidence, or explicit uncertainty).

5. **Context isolation**: Each agent operates in its own context window. Handoffs
   between agents use structured markdown documents, not raw conversation.

6. **Anti-hallucination gate**: Reviewer checks all numerical claims, dates, and
   quoted text against original sources. Any unverifiable claim is downgraded to
   "unconfirmed" or removed.

## Output Format

Final deliverable from Team Lead follows this structure:

```markdown
# Research Report: [Topic]

## Executive Summary
[2-3 paragraph synthesis]

## Key Findings
1. [Finding with source]
2. [Finding with source]
...

## Detailed Analysis
### [Sub-topic 1]
...

## Data Tables
| Metric | Value | Source | Confidence |
|--------|-------|--------|------------|
| ...    | ...   | ...    | High/Med/Low |

## Contradictions & Uncertainties
[Explicit listing of unresolved conflicts]

## Sources
[Numbered list of all URLs cited]

## Review Notes
[Summary of Reviewer feedback and how it was addressed]
```

## Usage

```bash
# From project root, invoke the research team:
claude --team teams/templates/research-team.md \
  --prompt "Research [topic]: [specific question]"
```

## When to Use

- Market research and competitive analysis
- Technology evaluation and comparison
- Trend identification and forecasting
- Literature review and evidence synthesis
- Due diligence investigations
