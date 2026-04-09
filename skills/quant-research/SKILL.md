---
name: quant-research
description: Quantitative research methodology — idea generation, mathematical verification,
  signal construction, backtesting, and dealing with common pitfalls. Also provides
  vault search and alpha idea generation via the quant-research-vault MCP.
  Auto-triggers on all quant research, strategy development, and backtesting tasks.
---

# Quant Research Skill

When doing any quantitative research task, follow the full methodology at:
`C:/Users/heiwa/Documents/ClaudeVault/guidelines/quant-research-methodology.md`

Or search the vault:
```bash
python C:/Users/heiwa/Desktop/quant-research-vault/research.py --search "<topic>"
python C:/Users/heiwa/Desktop/quant-research-vault/research.py --alpha-ideas "<topic>"
```

---

## Core Principles (Quick Reference)

### Before touching data
1. State the **mechanism** — why should this signal work?
2. Identify who takes the other side and why
3. Derive theoretical predictions, check limiting cases
4. Estimate break-even transaction cost

### Signal validity checklist
- [ ] Point-in-time correctness (no look-ahead, include reporting lags)
- [ ] Survivorship-bias-free universe
- [ ] Cross-sectional rank-transform + winsorize at 1/99th pct
- [ ] Tested walk-forward across 2+ full market cycles
- [ ] OOS Sharpe ≥ 0.5× in-sample Sharpe
- [ ] Permutation test p < 0.05

### Red flags (stop and investigate)
- In-sample Sharpe > 3× out-of-sample Sharpe
- >5 free parameters per year of data
- Strategy "needs" tight stops to work
- IC positive but net P&L negative (→ check decay speed vs rebalance freq)

### Key formula
```
Net Sharpe = Gross IC * sqrt(breadth) - 2 * turnover * cost_per_unit
Break-even cost = IC * vol_spread / sqrt(2)
```

---

## Signal Idea Template

Fill this out before coding ANY new strategy:

```
Signal: [Name]
Hypothesis: [What predicts what, over what horizon]
Mechanism: [Why should this relationship exist?]
Related papers: [search vault for 3 closest]

Construction:
  Universe: [which assets]
  Signal: [exact formula]
  Rebalance: [frequency]
  Position sizing: [how weights are assigned]

Expected properties:
  IC estimate: [from literature]
  Holding period: [days/weeks/months]
  Turnover: [% per period]
  Break-even cost: [bps]

Failure modes: [when/why this fails]

Verification plan:
  1. In-sample: [period, expected IC]
  2. OOS: [held-out period]
  3. Permutation test: [threshold]
  4. Cost model: [assumptions]
```

---

## Vault MCP Tools (if MCP server running)

```
search_papers(query, n_results=10)     — semantic search across all papers
get_paper(arxiv_id)                    — full summary of a specific paper
list_recent_papers(days=14)            — latest additions
generate_alpha_ideas(topic, n=5)       — Claude synthesizes alpha ideas from papers
get_vault_stats()                      — index health
```

---

## Crypto vs HK Equity Overlays

**Crypto:** 24/7 market (no day-of-week effects), perpetual funding rates in cost model,
fragmented liquidity (cross-exchange arbitrage), near-1.0 crash correlation, wash trading
inflates volume signals, regulatory/exchange failure tail risk.

**HK Equity:** A-H premium divergence opportunities, lot size constraints on small caps,
SFC-approved short selling list only, semi-annual reporting (less frequent than US),
stamp duty 0.1% per trade side.
