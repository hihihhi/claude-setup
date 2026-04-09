#!/usr/bin/env python3
"""Generate the Claude Code Harness Architecture Report as PDF."""

from fpdf import FPDF
import os

OUTPUT = os.path.join(os.path.dirname(__file__),
                      "Claude_Code_Harness_Report.pdf")


class Report(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 8, "Claude Code Harness Report", align="L")
        self.cell(0, 8, f"Page {self.page_no()}", align="R", new_x="LMARGIN",
                  new_y="NEXT")
        self.line(10, 14, 200, 14)
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, "April 9, 2026  |  Confidential", align="C")

    def title_page(self):
        self.add_page()
        self.ln(50)
        self.set_font("Helvetica", "B", 28)
        self.set_text_color(20, 60, 120)
        self.cell(0, 15, "Claude Code Harness", align="C",
                  new_x="LMARGIN", new_y="NEXT")
        self.ln(2)
        self.set_font("Helvetica", "", 18)
        self.set_text_color(60, 60, 60)
        self.cell(0, 12, "Architecture & Modifications Report",
                  align="C", new_x="LMARGIN", new_y="NEXT")
        self.ln(20)
        self.set_draw_color(20, 60, 120)
        self.set_line_width(0.8)
        self.line(60, self.get_y(), 150, self.get_y())
        self.ln(20)
        self.set_font("Helvetica", "", 12)
        self.set_text_color(80, 80, 80)
        self.cell(0, 8, "Date: April 9, 2026", align="C",
                  new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 8, "Version: 1.0.0", align="C",
                  new_x="LMARGIN", new_y="NEXT")
        self.cell(0, 8, "Classification: Internal", align="C",
                  new_x="LMARGIN", new_y="NEXT")

    def section(self, num, title):
        self.ln(6)
        self.set_font("Helvetica", "B", 16)
        self.set_text_color(20, 60, 120)
        self.cell(0, 10, f"{num}. {title}", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(20, 60, 120)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)
        self.set_text_color(30, 30, 30)

    def subsection(self, title):
        self.ln(3)
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(40, 80, 140)
        self.cell(0, 8, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)
        self.set_text_color(30, 30, 30)

    def body(self, text):
        self.set_font("Helvetica", "", 10)
        self.multi_cell(0, 5.5, text)
        self.ln(2)

    def bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(10)
        self.multi_cell(w=190, h=5.5, text=f"  -  {text}",
                        new_x="LMARGIN", new_y="NEXT")

    def code_block(self, text):
        self.set_font("Courier", "", 9)
        self.set_fill_color(240, 240, 245)
        self.multi_cell(0, 5, text, fill=True)
        self.ln(2)
        self.set_font("Helvetica", "", 10)

    def kv_table(self, rows):
        self.set_font("Helvetica", "B", 9)
        self.set_fill_color(20, 60, 120)
        self.set_text_color(255, 255, 255)
        self.cell(55, 7, "  Component", fill=True)
        self.cell(0, 7, "  Details", fill=True, new_x="LMARGIN",
                  new_y="NEXT")
        self.set_text_color(30, 30, 30)
        fill = False
        for key, val in rows:
            self.set_font("Helvetica", "B", 9)
            if fill:
                self.set_fill_color(245, 245, 250)
            else:
                self.set_fill_color(255, 255, 255)
            self.cell(55, 6, f"  {key}", fill=True)
            self.set_font("Helvetica", "", 9)
            self.cell(0, 6, f"  {val}", fill=True, new_x="LMARGIN",
                      new_y="NEXT")
            fill = not fill
        self.ln(4)


def build():
    pdf = Report()
    pdf.set_auto_page_break(auto=True, margin=20)

    # --- Title ---
    pdf.title_page()

    # --- TOC ---
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color(20, 60, 120)
    pdf.cell(0, 12, "Table of Contents", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)
    toc = [
        "1. Executive Summary",
        "2. Architecture Overview",
        "3. What Was Modified",
        "4. Hook System -- Bug Fix & Implications",
        "5. Memory System Design",
        "6. Multi-Agent Team Templates",
        "7. Security Hardening",
        "8. Role-Based Configuration",
        "9. Implications & Next Steps",
    ]
    for item in toc:
        pdf.set_font("Helvetica", "", 11)
        pdf.set_text_color(40, 40, 40)
        pdf.cell(0, 7, f"    {item}", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)

    # --- 1. Executive Summary ---
    pdf.add_page()
    pdf.section(1, "Executive Summary")
    pdf.body(
        "This report documents the design, implementation, and deployment of "
        "the Claude Code Harness -- a unified, one-click installer that "
        "configures Claude Code for maximum team efficiency with zero manual "
        "setup. The harness handles research pipelines, full development "
        "workflows, multi-agent teams, persistent memory, and automatic skill "
        "discovery across all employee roles."
    )
    pdf.subsection("Key Numbers")
    pdf.kv_table([
        ("ECC Plugin Skills", "181+ skills via everything-claude-code plugin"),
        ("Local Skills", "33 (14 superpowers + 19 mattpocock)"),
        ("Agents", "150 across 10 domains (agency-agents)"),
        ("Helper Scripts", "6 (memory-search, bash-guard, scan-secrets, etc.)"),
        ("Hooks", "5 (SessionStart, UserPromptSubmit, PreToolUse x2, Stop)"),
        ("Role Overlays", "6 (developer, researcher, designer, PM, devops, DS)"),
        ("Team Templates", "3 (research, dev, full-pipeline)"),
        ("CLAUDE.md", "103 lines (under 200-line budget)"),
    ])

    # --- 2. Architecture ---
    pdf.add_page()
    pdf.section(2, "Architecture Overview")
    pdf.body(
        "The harness follows a layered architecture where each layer provides "
        "a distinct capability. Layers are installed in order, with each "
        "building on the one below. The installer is idempotent -- running it "
        "twice produces the same result."
    )
    pdf.subsection("Layer Stack")
    layers = [
        ("Layer 0: Base", "everything-claude-code (ECC) -- 181 skills, 47 agents, "
         "hooks, rules engine, DevFleet orchestration, continuous learning"),
        ("Layer 1: Methodology", "superpowers (14 skills: TDD, verification, "
         "subagent-driven dev) + mattpocock/skills (19 skills: PRD-to-plan, "
         "grill-me, TDD, write-a-skill)"),
        ("Layer 2: Research", "last30days-skill (trend research), K-Dense "
         "scientific (134 domain skills), deer-flow (heavy research offloading)"),
        ("Layer 3: Role Agents", "agency-agents -- 150 agents across academic, "
         "design, engineering, marketing, product, sales, strategy, support"),
        ("Layer 4: Observability", "claude-hud -- real-time context budget, "
         "git status, active tool/agent monitoring"),
        ("Layer 5: Memory", "3-tier system: global CLAUDE.md + per-project "
         "auto-memory + cross-project MCP knowledge graph"),
        ("Layer 6: Custom", "Team CLAUDE.md, role overlays, team templates, "
         "custom hooks and scripts"),
    ]
    pdf.kv_table(layers)

    pdf.subsection("Coordination Principle")
    pdf.body(
        "Each layer serves a distinct purpose: ECC provides tooling, "
        "superpowers provides methodology, agency-agents provides role "
        "coverage, and the memory system provides persistence. The "
        "Generator != Evaluator principle is enforced throughout -- the agent "
        "that writes code never reviews it."
    )

    # --- 3. What Was Modified ---
    pdf.add_page()
    pdf.section(3, "What Was Modified")
    pdf.subsection("Clean Install Process")
    pdf.body(
        "The installation was performed from scratch on Windows 11. The "
        "existing ~/.claude/ directory (2.9 GB) was backed up via robocopy "
        "to ~/.claude-backup/ before any changes."
    )
    pdf.subsection("Preserved Data")
    pdf.bullet("Credentials (.credentials.json) -- login/auth tokens")
    pdf.bullet("Conversation history (history.jsonl)")
    pdf.bullet("24 project memory directories (projects/*/memory/)")
    pdf.bullet("Session data, cache, IDE settings")
    pdf.ln(2)
    pdf.subsection("Removed & Replaced")
    pdf.bullet("All skills/ -- replaced with superpowers + mattpocock")
    pdf.bullet("All hooks/ -- replaced with new hook scripts")
    pdf.bullet("All scripts/ -- replaced with 6 new helper scripts")
    pdf.bullet("All agents/ -- replaced with 150 agency-agents")
    pdf.bullet("CLAUDE.md -- replaced with 103-line navigation index")
    pdf.bullet("settings.json -- rebuilt with corrected hook format")
    pdf.bullet("rules/, workflow/, teams/ -- cleaned for fresh config")
    pdf.ln(2)
    pdf.subsection("New settings.json Configuration")
    pdf.body(
        "The new settings.json configures 5 hooks (SessionStart, "
        "UserPromptSubmit, PreToolUse x2, Stop), enables 5 plugins "
        "(ECC, document-skills, fullstack-dev-skills, frontend-design, "
        "oh-my-mermaid), and sets model to Opus with bypassPermissions mode."
    )

    # --- 4. Hook System ---
    pdf.add_page()
    pdf.section(4, "Hook System -- Bug Fix & Implications")
    pdf.subsection("The Problem")
    pdf.body(
        "The initial hook scripts used a deprecated response format: "
        '{"decision": "allow"} or {"decision": "block", "reason": "..."}. '
        "This caused Claude Code to report hook errors on every tool call, "
        "generating noisy error messages in the UI."
    )
    pdf.subsection("The Fix")
    pdf.body(
        "Migrated to the current Claude Code hook response format:"
    )
    pdf.code_block(
        '{\n'
        '  "hookSpecificOutput": {\n'
        '    "hookEventName": "PreToolUse",\n'
        '    "permissionDecision": "allow|deny",\n'
        '    "permissionDecisionReason": "optional explanation"\n'
        '  }\n'
        '}'
    )
    pdf.subsection("Key Insights")
    pdf.bullet("Empty stdout = proceed normally (no hook decision applied)")
    pdf.bullet("Exit code 0 with JSON = decision is processed")
    pdf.bullet("Exit code 2 = hard block without JSON output")
    pdf.bullet("Other non-zero exit codes = non-blocking error, tool proceeds")
    pdf.bullet("On 'allow': output NOTHING (not JSON) -- this is the cleanest")
    pdf.bullet("On 'deny': output the hookSpecificOutput JSON with reason")
    pdf.ln(2)
    pdf.subsection("Implication")
    pdf.body(
        "All future custom hooks must use this format. The PostToolUse "
        "prettier hook was removed entirely because it caused errors when "
        "prettier was not installed in the current project. Auto-formatting "
        "should be handled per-project via pre-commit hooks instead."
    )

    # --- 5. Memory System ---
    pdf.add_page()
    pdf.section(5, "Memory System Design")
    pdf.subsection("Three-Tier Architecture")
    tiers = [
        ("Tier 1: Always Loaded", "CLAUDE.md (103 lines) + rules/*.md -- under "
         "5,000 tokens total. Loaded into every conversation automatically."),
        ("Tier 2: Per-Project", "~/.claude/projects/<proj>/memory/MEMORY.md "
         "index file pointing to topic-specific .md files. Claude auto-creates "
         "these as it learns about projects."),
        ("Tier 3: Cross-Project", "MCP memory server providing a knowledge "
         "graph that spans all projects. Enables recalling information from "
         "Project A while working in Project B."),
    ]
    pdf.kv_table(tiers)

    pdf.subsection("Dynamic Memory Injection")
    pdf.body(
        "The UserPromptSubmit hook runs memory-search.py on every user "
        "message. It extracts keywords from the prompt, searches all "
        "~/.claude/projects/*/memory/*.md files using TF-IDF scoring, and "
        "injects the top 3 most relevant memory files into context. This "
        "provides automatic recall without loading all memory into every "
        "conversation. The search runs in under 1 second across ~100 files."
    )

    # --- 6. Multi-Agent Teams ---
    pdf.section(6, "Multi-Agent Team Templates")
    pdf.subsection("Research Team")
    pdf.body(
        "Opus lead coordinates and synthesizes. Four Sonnet agents handle "
        "web search/trends, deep topic dives, data analysis, and fact-checking. "
        "The reviewer agent must not be the same agent that produced findings "
        "(Generator != Evaluator)."
    )
    pdf.subsection("Dev Team")
    pdf.body(
        "Opus architect designs and plans. Two Sonnet implementers work in "
        "isolated git worktrees (non-overlapping file domains). A Sonnet "
        "tester writes tests first (TDD). A separate Sonnet reviewer handles "
        "code review and security scanning. Max 400 lines per agent session."
    )
    pdf.subsection("Full Pipeline")
    pdf.body(
        "Opus director orchestrates three pods: Research (researcher + analyst), "
        "Dev (implementer + tester), Quality (reviewer + security). Five "
        "mandatory phase gates with structured handoff documents between pods."
    )

    # --- 7. Security ---
    pdf.add_page()
    pdf.section(7, "Security Hardening")
    pdf.subsection("bash-guard.py -- Command Blocklist")
    blocked = [
        ("rm -rf /", "Recursive delete of root filesystem"),
        ("rm -rf ~ / $HOME", "Recursive delete of home directory"),
        ("git push --force main", "Force push to main/master branch"),
        ("sudo rm / sudo dd", "Privileged destructive operations"),
        ("curl | sh", "Piping remote content to shell"),
        ("DROP TABLE/DATABASE", "SQL destruction commands"),
        ("chmod 777", "World-writable permissions"),
        ("Fork bombs", "Shell fork bomb patterns and variants"),
    ]
    pdf.kv_table(blocked)
    pdf.body(
        "git reset --hard triggers a warning but is allowed (not blocked). "
        "The hook reads the Bash command from stdin JSON and matches against "
        "regex patterns. Uses stdlib only -- no external dependencies."
    )

    pdf.subsection("scan-secrets.py -- Secret Detection")
    detected = [
        ("API Key Prefixes", "OpenAI (sk-), Stripe (pk_/sk_live_), AWS (AKIA)"),
        ("VCS Tokens", "GitHub (ghp_, gho_), GitLab (glpat-)"),
        ("Chat Tokens", "Slack bot (xoxb-), Slack user (xoxp-)"),
        ("AWS Secrets", "aws_secret_access_key patterns (40-char base64)"),
        ("Private Keys", "RSA, EC, OPENSSH, DSA, PGP private key headers"),
        ("Hardcoded Creds", "Assignments to password/secret/token/api_key vars"),
        ("Connection Strings", "Database URIs with embedded credentials"),
    ]
    pdf.kv_table(detected)
    pdf.body(
        "Skips .md files (documentation may discuss patterns) and test files "
        "with obvious fake values (test, example, placeholder, TODO). Also "
        "skips environment variable lookups (os.environ, process.env)."
    )

    # --- 8. Role Config ---
    pdf.add_page()
    pdf.section(8, "Role-Based Configuration")
    pdf.body(
        "Six role overlays are installed to ~/.claude/config/roles/. Each "
        "overlay defines phase routing (which skill to invoke for which user "
        "intent), priority skills, preferred agents, and a step-by-step "
        "workflow. The installer selects roles at install time."
    )
    roles = [
        ("Developer", "TDD, code-review, security-review, build-error-resolver. "
         "Architect (Opus) + Implementer/Tester/Reviewer (Sonnet)."),
        ("Researcher", "deep-research, last30days, market analysis, scientific. "
         "Researcher + Analyst + Reviewer agents."),
        ("Designer", "Impeccable suite (critique/arrange/colorize/typeset/polish), "
         "shadcn-ui, frontend-patterns. WCAG AA standards."),
        ("Product Manager", "PRD-to-plan, grill-me, office-hours, feature-forge. "
         "Success criteria and scope control focus."),
        ("DevOps/SRE", "Deploy, Docker, Terraform, CI/CD, monitoring. "
         "IaC-first with incident response framework."),
        ("Data Scientist", "PyTorch, eval harness, HuggingFace, MLflow. "
         "Reproducibility standards and experiment tracking."),
    ]
    pdf.kv_table(roles)

    # --- 9. Implications ---
    pdf.section(9, "Implications & Next Steps")
    pdf.subsection("What This Means")
    pdf.bullet("Context budget stays under 5K tokens always-loaded (CLAUDE.md "
               "is 103 lines). Skills load on demand via routing table.")
    pdf.bullet("Memory persists across sessions and projects. Cross-project "
               "recall works via MCP memory server + dynamic injection hook.")
    pdf.bullet("Multi-agent teams can be instantiated from 3 pre-built "
               "templates with one command.")
    pdf.bullet("Security hooks block dangerous commands and detect secrets "
               "before they reach disk.")
    pdf.bullet("Cross-platform: all scripts work on Windows, Mac, and Linux.")
    pdf.bullet("Idempotent: the installer can run multiple times safely with "
               "backup before destructive changes.")
    pdf.ln(4)
    pdf.subsection("Next Steps")
    pdf.bullet("Push claude-setup repo to GitHub")
    pdf.bullet("Install GitHub CLI (gh) for repo management")
    pdf.bullet("Test installer on a fresh Windows machine")
    pdf.bullet("Add CI workflow for skill validation")
    pdf.bullet("Configure last30days-skill (needs ScrapeCreators API key)")
    pdf.bullet("Evaluate claude-hud when package is published")
    pdf.bullet("Train team members on role selection and team templates")

    pdf.output(OUTPUT)
    print(f"PDF saved to: {OUTPUT}")
    print(f"Pages: {pdf.pages_count}")


if __name__ == "__main__":
    build()
