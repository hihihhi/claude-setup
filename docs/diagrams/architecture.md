# Claude Setup — Architecture Diagrams

---

## Diagram 1 — Layer Stack

How the 7 layers compose into a unified Claude Code environment.
Each layer builds on the ones below it; Claude Code consumes all of them.

```mermaid
graph TB
    CC(["🤖 Claude Code"])

    subgraph L7["Layer 7 — Skills"]
        direction LR
        KG["karpathy-guidelines\n(Think·Simplicity·Surgical·Goal-Driven)"]
        DR["deep-research\n(5-stage pipeline · IRON RULE · anti-sycophancy)"]
    end

    subgraph L6["Layer 6 — Config & Templates"]
        direction LR
        CM["CLAUDE.md\n(global nav index, <5K tokens)"]
        RO["6 role overlays\n(dev · researcher · designer · PM · devops · data)"]
        TT["3 team templates\n(research · dev · full-pipeline)"]
    end

    subgraph L5["Layer 5 — Memory & Security"]
        direction LR
        MS["memory-search.py\n(UserPromptSubmit · TF-IDF injection)"]
        BG["bash-guard.py\n(PreToolUse · blocks rm -rf · force push)"]
        SS["scan-secrets.py\n(PreToolUse · detects API keys · tokens)"]
        US["update-state.py\n(Stop · writes session summary)"]
        MM["MCP memory server\n(knowledge graph · entities.jsonl)"]
    end

    subgraph L4["Layer 4 — Observability"]
        HUD["HUD status line\nuser:path  branch*  ctx:%  model  time  todos:N"]
    end

    subgraph L3["Layer 3 — Agents"]
        AA["agency-agents  100+ agents\n(engineering · design · marketing\nsales · product · support · academic)"]
    end

    subgraph L2["Layer 2 — Research"]
        L30["last30days-skill\n(Reddit · X · HN · YouTube · TikTok)"]
        DRS["deep-research skill\n(flash / standard / pro / deep modes)"]
    end

    subgraph L1["Layer 1 — Methodology"]
        SP["superpowers  14 skills\n(TDD · verify · Generator≠Evaluator)"]
        MP["mattpocock/skills\n(SKILL.md format · PRD-to-plan · grill-me)"]
        IM["impeccable  21 skills\n(critique → arrange → colorize → polish)"]
    end

    subgraph L0["Layer 0 — ECC Base Infrastructure"]
        direction LR
        SKL["181 skills\n(routing table · auto-select)"]
        AGT["47 agents\n(planner · architect · reviewer · TDD · security)"]
        HKS["20+ hooks\n(session · memory · security · state)"]
        DF["DevFleet\n(multi-agent · tmux · worktrees)"]
        CL["continuous learning\n(auto-generate skills from tasks)"]
        CB["context budget\n(/context-budget · /strategic-compact)"]
    end

    CC --> L7
    L7 --> L6
    L6 --> L5
    L5 --> L4
    L4 --> L3
    L3 --> L2
    L2 --> L1
    L1 --> L0
```

---

## Diagram 2 — Hook Execution Flow

How hooks intercept Claude Code's lifecycle at 5 event points.
Hooks run as shell commands; Claude sees their stdout as injected context or a block decision.

```mermaid
sequenceDiagram
    participant U as User
    participant CC as Claude Code
    participant H as Hook
    participant S as Script

    rect rgb(30, 80, 120)
        Note over U,S: SessionStart
        CC->>H: session begins
        H->>S: cat ~/.claude/projects/<proj>/state.md
        S-->>CC: inject last session summary into context
    end

    rect rgb(40, 100, 60)
        Note over U,S: UserPromptSubmit
        U->>CC: types a message
        CC->>H: UserPromptSubmit event
        H->>S: memory-search.py (reads prompt from stdin)
        S->>S: TF-IDF keyword extraction
        S->>S: scan all project memory/*.md files
        S-->>CC: inject top 3 matching memory snippets
        CC->>CC: Claude now sees enriched context
    end

    rect rgb(100, 60, 30)
        Note over U,S: PreToolUse — Bash
        CC->>H: about to run Bash tool
        H->>S: bash-guard.py (receives tool input JSON)
        S->>S: regex match against danger patterns
        alt dangerous command
            S-->>CC: JSON deny + reason → tool blocked
        else safe
            S-->>CC: empty stdout → tool proceeds
        end
    end

    rect rgb(100, 60, 30)
        Note over U,S: PreToolUse — Write / Edit
        CC->>H: about to write or edit a file
        H->>S: scan-secrets.py (receives file content)
        S->>S: regex match against secret patterns
        alt secret detected (API key, token, private key)
            S-->>CC: JSON deny + matched pattern → write blocked
        else clean
            S-->>CC: empty stdout → write proceeds
        end
    end

    rect rgb(60, 30, 100)
        Note over U,S: Stop
        CC->>H: session ending
        H->>S: update-state.py
        S->>S: write timestamp + session summary
        S-->>S: ~/.claude/projects/<proj>/state.md updated
    end
```

---

## Diagram 3 — 3-Tier Memory System

How context is persisted and retrieved across sessions and projects.

```mermaid
flowchart LR
    subgraph T1["Tier 1 — Always Loaded (global)"]
        direction TB
        CM["~/.claude/CLAUDE.md\n< 200 lines · < 5K tokens\nnavigation index + routing tables"]
        RU["~/.claude/rules/*.md\nalways-on behavioral rules"]
    end

    subgraph T2["Tier 2 — Per-Project (on demand)"]
        direction TB
        PF["~/.claude/projects/*/memory/*.md\nfeedback · project context\nreferences · user profile"]
        MS["memory-search.py\nTF-IDF keyword match\ntop 3 results injected"]
    end

    subgraph T3["Tier 3 — Cross-Project (knowledge graph)"]
        direction TB
        MCP["MCP memory server\nentities.jsonl\npersistent across all projects"]
        KG["Knowledge graph\ncreate · search · relate entities\nvia mcp__memory__* tools"]
    end

    subgraph SESS["Claude Code Session"]
        CTX["Active Context Window"]
        HOOK["UserPromptSubmit Hook"]
        PROMPT["User Prompt"]
    end

    CM -->|"injected at startup"| CTX
    RU -->|"injected at startup"| CTX

    PROMPT --> HOOK
    HOOK -->|"extract keywords"| MS
    MS -->|"scan files"| PF
    PF -->|"top 3 matches"| HOOK
    HOOK -->|"prepend to prompt"| CTX

    MCP <-->|"tool calls\n(search · add · relate)"| KG
    KG -->|"Claude calls\nmcp__memory__search_nodes"| CTX

    style T1 fill:#1e4d6b,color:#fff
    style T2 fill:#2d5a27,color:#fff
    style T3 fill:#5a2d6b,color:#fff
    style SESS fill:#3d3d20,color:#fff
```
